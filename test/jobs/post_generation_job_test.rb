require "test_helper"
require "stringio"

class PostGenerationJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "marks configuration failures without retrying them" do
    generation = build_generation

    service = Object.new
    service.define_singleton_method(:call) do
      raise RubyLLM::ConfigurationError, "missing key"
    end

    with_service(service) do
      PostGenerationJob.perform_now(generation)
    end

    assert generation.reload.failed?
    assert_equal "configuration", generation.failure_reason
  end

  test "reschedules transient provider failures instead of marking them failed" do
    generation = build_generation

    service = Object.new
    service.define_singleton_method(:call) do
      raise RubyLLM::RateLimitError, "try later"
    end

    assert_enqueued_with job: PostGenerationJob do
      with_service(service) do
        PostGenerationJob.perform_now(generation)
      end
    end

    assert_not generation.reload.failed?
  end

  private

    def with_service(service)
      original_new = PostGenerations::Service.method(:new)
      PostGenerations::Service.define_singleton_method(:new) { |_post_generation| service }
      yield
    ensure
      PostGenerations::Service.define_singleton_method(:new, original_new)
    end

    def build_generation
      generation = users(:one).post_generations.new(source_locale: "en")
      generation.audio.attach(
        io: StringIO.new("audio"),
        filename: "recording.webm",
        content_type: "audio/webm"
      )
      generation.save!
      generation
    end
end
