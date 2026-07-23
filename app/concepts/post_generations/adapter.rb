class PostGenerations::Adapter
  def transcribe(path, language:, prompt:)
    RubyLLM.transcribe(
      path,
      provider: :openai,
      language: language,
      prompt: prompt
    )
  end

  def generate(input, instructions:, schema:)
    RubyLLM
      .chat(
        model: RubyLLM.config.default_model,
        provider: :openai,
        assume_model_exists: true
      )
      .with_thinking(effort: :high)
      .with_instructions(instructions)
      .with_schema(schema)
      .ask(input)
  end
end
