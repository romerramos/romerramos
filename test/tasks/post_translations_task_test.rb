require "test_helper"
require "rake"

class PostTranslationsTaskTest < ActiveSupport::TestCase
  class FakeAdapter
    attr_reader :inputs, :instructions, :schema

    def initialize
      @inputs = []
    end

    def generate(input, instructions:, schema:)
      @inputs << JSON.parse(input)
      @instructions = instructions
      @schema = schema

      Struct.new(:content).new(
        {
          "en" => {
            "title" => "An unchanged English title",
            "description" => "An unchanged English description",
            "content" => "Unchanged English content"
          },
          "es" => {
            "title" => "Un borrador venezolano",
            "description" => "Una descripcion venezolana",
            "content" => "Contenido venezolano"
          }
        }
      )
    end
  end

  setup do
    unless Rake::Task.task_defined?("post_translations:backfill_publication") &&
        Rake::Task.task_defined?("post_translations:regenerate_spanish_drafts")
      Rails.application.load_tasks
    end
    @task = Rake::Task["post_translations:backfill_publication"]
    @task.reenable
    @regeneration_task = Rake::Task["post_translations:regenerate_spanish_drafts"]
    @regeneration_task.reenable
  end

  test "backfills only legacy translation publication state" do
    published_at = 1.day.ago
    post = Post.create!(
      published: true,
      published_at: published_at,
      post_translations_attributes: {
        "0" => { locale: "en", title: "Legacy", content: "Body" },
        "1" => { locale: "es", title: "Intentional draft", content: "Contenido", published: false }
      }
    )
    english = post.post_translation_for(:en)
    english.update_column(:published, nil)

    @task.invoke

    assert english.reload.published?
    assert_in_delta published_at, english.published_at, 1.second
    assert_not post.post_translation_for(:es).reload.published?

    @task.reenable
    assert_no_changes -> { english.reload.attributes.slice("published", "published_at") } do
      @task.invoke
    end
  end

  test "regenerates only unprocessed Spanish drafts from the English translation" do
    post = Post.create!(
      post_translations_attributes: {
        "0" => {
          locale: "en",
          title: "An English title",
          description: "An English description",
          content: "English content",
          published: true
        },
        "1" => {
          locale: "es",
          title: "Titulo anterior",
          description: "Descripcion anterior",
          content: "Contenido anterior",
          published: false
        }
      }
    )
    english = post.post_translations.find_by!(locale: "en")
    spanish = post.post_translations.find_by!(locale: "es")
    adapter = FakeAdapter.new
    task = @regeneration_task

    with_adapter(adapter) do
      task.invoke
    end

    spanish.reload
    assert_equal "Un borrador venezolano", spanish.title
    assert_equal "Una descripcion venezolana", spanish.description
    assert_equal "Contenido venezolano", spanish.content
    assert_not spanish.published?
    assert_not_nil spanish.spanish_draft_regenerated_at
    assert_equal(
      {
        "source_locale" => "en",
        "transcript" => "Title: An English title\n\nDescription: An English description\n\nContent:\n\nEnglish content"
      },
      adapter.inputs.first
    )
    assert_equal PostGenerations::Service::WRITING_INSTRUCTIONS, adapter.instructions
    assert_equal PostGenerations::Schema, adapter.schema
    assert_equal "An English title", english.reload.title
    assert_equal "English content", english.content

    task.reenable
    assert_no_changes -> { spanish.reload.attributes } do
      with_adapter(adapter) do
        task.invoke
      end
    end
    assert_equal 1, adapter.inputs.size
  end

  test "does not regenerate published Spanish translations" do
    post = Post.create!(
      post_translations_attributes: {
        "0" => { locale: "en", title: "An English title", content: "English content", published: true },
        "1" => { locale: "es", title: "Published title", content: "Published content", published: true }
      }
    )
    spanish = post.post_translations.find_by!(locale: "es")
    adapter = FakeAdapter.new
    task = @regeneration_task

    with_adapter(adapter) do
      task.invoke
    end

    assert_empty adapter.inputs
    assert_equal "Published title", spanish.reload.title
    assert_nil spanish.spanish_draft_regenerated_at
  end

  private

    def with_adapter(adapter)
      original_new = PostGenerations::Adapter.method(:new)
      PostGenerations::Adapter.define_singleton_method(:new) { adapter }
      yield
    ensure
      PostGenerations::Adapter.define_singleton_method(:new, original_new)
    end
end
