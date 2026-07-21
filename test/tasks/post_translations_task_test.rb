require "test_helper"
require "rake"

class PostTranslationsTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("post_translations:backfill_publication")
    @task = Rake::Task["post_translations:backfill_publication"]
    @task.reenable
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
end
