class PostGenerationJob < ApplicationJob
  queue_as :llm

  TRANSIENT_ERRORS = [
    Faraday::TimeoutError,
    Faraday::ConnectionFailed,
    RubyLLM::RateLimitError,
    RubyLLM::ServerError,
    RubyLLM::ServiceUnavailableError,
    RubyLLM::OverloadedError
  ].freeze

  # Must outlast a worst-case run: the transcription and generation calls each
  # get RubyLLM's request_timeout, so the lock has to survive both.
  limits_concurrency(
    to: 1,
    key: ->(post_generation) { post_generation.id },
    duration: 30.minutes
  )

  retry_on(*TRANSIENT_ERRORS, wait: :polynomially_longer, attempts: 3) do |job, error|
    post_generation = job.arguments.first
    post_generation.fail!("provider_unavailable") unless post_generation.completed?

    Rails.error.report(
      error,
      context: { post_generation_id: post_generation.id }
    )
  end

  def perform(post_generation)
    PostGenerations::Service.new(post_generation).call
  rescue *TRANSIENT_ERRORS
    raise
  rescue RubyLLM::ContextLengthExceededError => error
    fail_generation(post_generation, "content_too_long", error)
  rescue RubyLLM::BadRequestError => error
    fail_generation(post_generation, "invalid_audio", error)
  rescue RubyLLM::ConfigurationError,
         RubyLLM::ModelNotFoundError,
         RubyLLM::UnauthorizedError,
         RubyLLM::ForbiddenError,
         RubyLLM::PaymentRequiredError => error
    fail_generation(post_generation, "configuration", error)
  rescue StandardError => error
    post_generation.fail!("unexpected") unless post_generation.completed?
    Rails.error.report(
      error,
      context: { post_generation_id: post_generation.id }
    )
    raise
  end

  private

    def fail_generation(post_generation, reason, error)
      post_generation.fail!(reason) unless post_generation.completed?

      Rails.error.report(
        error,
        handled: true,
        context: { post_generation_id: post_generation.id }
      )
    end
end
