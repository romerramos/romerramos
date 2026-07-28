require "test_helper"

class PostTranslations::ServiceTest < ActiveSupport::TestCase
  class FakeAdapter
    attr_reader :input, :instructions, :schema, :effort

    def initialize(rewritten: "a much tighter sentence")
      @rewritten = rewritten
    end

    def generate(input, instructions:, schema:, effort: :high)
      @input = JSON.parse(input)
      @instructions = instructions
      @schema = schema
      @effort = effort

      Struct.new(:content).new({ "rewritten" => @rewritten })
    end
  end

  test "replaces only the selected passage and leaves the record unsaved" do
    translation = build_translation("Keep this. Rewrite me. Keep that too.")
    adapter = FakeAdapter.new

    assert PostTranslations::Service.new(translation, adapter: adapter)
      .rewrite_selection(selection: "Rewrite me.", selection_start: 11, selection_end: 22)

    assert_equal "Keep this. a much tighter sentence Keep that too.", translation.content
    assert translation.changed?
    assert_equal "Keep this. Rewrite me. Keep that too.", translation.reload.content
  end

  test "sends the locale, selection, full content and instruction to the adapter" do
    translation = build_translation("Keep this. Rewrite me. Keep that too.", locale: "es")
    adapter = FakeAdapter.new

    PostTranslations::Service.new(translation, adapter: adapter).rewrite_selection(
      selection: "Rewrite me.",
      selection_start: 11,
      selection_end: 22,
      instruction: "make it shorter"
    )

    assert_equal "es", adapter.input.fetch("locale")
    assert_equal "Rewrite me.", adapter.input.fetch("selection")
    assert_equal "Keep this. Rewrite me. Keep that too.", adapter.input.fetch("content")
    assert_equal "make it shorter", adapter.input.fetch("instruction")
    assert_equal PostTranslations::Service::REWRITE_INSTRUCTIONS, adapter.instructions
    assert_equal PostTranslations::Schema, adapter.schema
    assert_equal :low, adapter.effort
  end

  test "refuses to splice when the text moved under the stored offsets" do
    translation = build_translation("The author kept typing after selecting.")
    adapter = FakeAdapter.new

    assert_not PostTranslations::Service.new(translation, adapter: adapter)
      .rewrite_selection(selection: "Rewrite me.", selection_start: 11, selection_end: 22)

    assert_equal "The author kept typing after selecting.", translation.content
    assert_nil adapter.input
  end

  test "refuses an empty or inverted selection" do
    translation = build_translation("Some content.")
    adapter = FakeAdapter.new
    service = PostTranslations::Service.new(translation, adapter: adapter)

    assert_not service.rewrite_selection(selection: "", selection_start: 0, selection_end: 0)
    assert_not service.rewrite_selection(selection: "Some", selection_start: 4, selection_end: 0)
    assert_nil adapter.input
  end

  private

    def build_translation(content, locale: "en")
      post = Post.create!(
        post_translations_attributes: {
          "0" => { locale: "en", title: "A title", content: content },
          "1" => { locale: "es", title: "Un título", content: content }
        }
      )
      post.post_translation_for(locale)
    end
end
