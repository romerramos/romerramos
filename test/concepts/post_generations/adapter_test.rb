require "test_helper"

class PostGenerations::AdapterTest < ActiveSupport::TestCase
  class FakeChat
    attr_reader :instructions, :input, :model_options, :schema, :thinking

    def initialize(model_options)
      @model_options = model_options
    end

    def with_thinking(effort:)
      @thinking = effort
      self
    end

    def with_instructions(instructions)
      @instructions = instructions
      self
    end

    def with_schema(schema)
      @schema = schema
      self
    end

    def ask(input)
      @input = input
      :response
    end
  end

  test "transcribes through OpenAI with the supplied language and prompt" do
    calls = []
    result = with_ruby_llm_method(:transcribe, ->(path, **options) {
      calls << [ path, options ]
      :transcription
    }) do
      PostGenerations::Adapter.new.transcribe(
        "/tmp/recording.webm",
        language: "es",
        prompt: "Use Spanish punctuation."
      )
    end

    assert_equal :transcription, result
    assert_equal [
      [
        "/tmp/recording.webm",
        { provider: :openai, language: "es", prompt: "Use Spanish punctuation." }
      ]
    ], calls
  end

  test "uses the configured model with high reasoning and structured output" do
    fake_chat = nil
    schema = Object.new
    result = with_ruby_llm_method(:chat, ->(**options) {
      fake_chat = FakeChat.new(options)
    }) do
      PostGenerations::Adapter.new.generate(
        "source transcript",
        instructions: "Write faithfully.",
        schema: schema
      )
    end

    assert_equal :response, result
    assert_equal "gpt-5.6-sol", fake_chat.model_options[:model]
    assert_equal :openai, fake_chat.model_options[:provider]
    assert fake_chat.model_options[:assume_model_exists]
    assert_equal :high, fake_chat.thinking
    assert_equal "Write faithfully.", fake_chat.instructions
    assert_same schema, fake_chat.schema
    assert_equal "source transcript", fake_chat.input
  end

  private

    def with_ruby_llm_method(name, replacement)
      original_method = RubyLLM.method(name)
      RubyLLM.define_singleton_method(name) do |*args, **options|
        replacement.call(*args, **options)
      end
      yield
    ensure
      RubyLLM.define_singleton_method(name, original_method)
    end
end
