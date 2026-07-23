require "test_helper"
require "stringio"

class PostGenerations::ServiceTest < ActiveSupport::TestCase
  class FakeAdapter
    attr_reader :transcription_language, :transcription_prompt

    def transcribe(_path, language:, prompt:)
      @transcription_language = language
      @transcription_prompt = prompt
      Struct.new(:text, :model).new("This is the voice transcript.", "fake-transcriber")
    end

    def generate(_input, instructions:, schema:)
      @instructions = instructions
      @schema = schema

      Struct.new(:content, :model_id).new(
        {
          "en" => {
            "title" => "An English draft",
            "description" => "An English description",
            "content" => "English Markdown content"
          },
          "es" => {
            "title" => "Un borrador en español",
            "description" => "Una descripción en español",
            "content" => "Contenido Markdown en español"
          }
        },
        "fake-writer"
      )
    end
  end

  test "transcribes and creates unpublished English and Spanish drafts" do
    generation = build_generation
    generation.save!
    adapter = FakeAdapter.new

    PostGenerations::Service.new(generation, adapter: adapter).call

    generation.reload
    post = generation.post

    assert generation.completed?
    assert_equal "This is the voice transcript.", generation.transcript
    assert_equal "en", adapter.transcription_language
    assert_equal "fake-transcriber", generation.transcription_model
    assert_equal "fake-writer", generation.generation_model
    assert_not generation.audio.attached?
    assert_equal %w[en es], post.post_translations.pluck(:locale).sort
    assert post.post_translation_for(:en).content.present?
    assert post.post_translation_for(:es).content.present?
    assert_not post.post_translation_for(:en).published?
    assert_not post.post_translation_for(:es).published?
  end

  test "reuses a saved transcript instead of transcribing again" do
    generation = build_generation
    generation.transcript = "Previously saved transcript"
    generation.save!

    adapter = FakeAdapter.new
    adapter.define_singleton_method(:transcribe) do |**|
      raise "transcription should not be called"
    end

    PostGenerations::Service.new(generation, adapter: adapter).call

    assert generation.reload.completed?
    assert_equal "Previously saved transcript", generation.transcript
  end

  private

    def build_generation
      generation = users(:one).post_generations.new(source_locale: "en")
      generation.audio.attach(
        io: StringIO.new("audio"),
        filename: "recording.webm",
        content_type: "audio/webm"
      )
      generation
    end
end
