require "test_helper"
require "stringio"

class PostGenerationTest < ActiveSupport::TestCase
  test "accepts supported audio recordings" do
    generation = build_generation

    assert generation.valid?
  end

  test "requires a supported audio content type" do
    generation = build_generation(content_type: "image/jpeg")

    assert_not generation.valid?
    assert_includes generation.errors[:audio], "must be an audio recording (WEBM, MP4, OGG, WAV or MP3)"
  end

  test "rejects recordings larger than the upload limit" do
    generation = build_generation(contents: "a" * (PostGeneration::MAX_AUDIO_SIZE + 1))

    assert_not generation.valid?
    assert_includes generation.errors[:audio], "is too large (max 24MB)"
  end

  test "failed generations can be retried while their audio remains attached" do
    generation = build_generation
    generation.save!
    generation.fail!("unexpected")

    assert generation.retryable?

    generation.queue_for_retry!

    assert generation.queued?
    assert_nil generation.failure_reason
  end

  private

    def build_generation(content_type: "audio/webm", contents: "audio")
      generation = users(:one).post_generations.new(source_locale: "en")
      generation.audio.attach(
        io: StringIO.new(contents),
        filename: "recording.webm",
        content_type: content_type
      )
      generation
    end
end
