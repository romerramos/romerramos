RubyLLM.configure do |config|
  config.openai_api_key = ENV["OPENAI_API_KEY"].presence ||
    Rails.application.credentials.dig(:openai, :api_key)
  config.default_transcription_model = "gpt-4o-transcribe"
  config.default_model = "gpt-5.6-sol"
  config.request_timeout = 600
  config.max_retries = 1
  config.log_level = :info
end
