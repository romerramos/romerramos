class PostGeneration < ApplicationRecord
  # Kept under gpt-4o-transcribe's 25 minute ceiling. The recorder pins its
  # bitrate so this stays well inside MAX_AUDIO_SIZE.
  MAX_AUDIO_DURATION = 20.minutes

  # OpenAI rejects transcription uploads over 25MB.
  MAX_AUDIO_SIZE = 24.megabytes

  AUDIO_CONTENT_TYPES = %w[
    audio/mp4
    audio/mpeg
    audio/ogg
    audio/wav
    audio/webm
    audio/x-m4a
    video/mp4
    video/webm
  ].freeze

  FAILURE_REASONS = %w[
    configuration
    invalid_audio
    provider_unavailable
    content_too_long
    unexpected
  ].freeze

  belongs_to :user
  belongs_to :post, optional: true

  has_one_attached :audio

  enum :status, {
    queued: "queued",
    transcribing: "transcribing",
    generating: "generating",
    completed: "completed",
    failed: "failed"
  }, validate: true

  validates :source_locale, inclusion: { in: -> { I18n.available_locales.map(&:to_s) } }
  validates :audio, presence: true, on: :create
  validates :failure_reason, inclusion: { in: FAILURE_REASONS }, allow_nil: true
  validates :failure_reason, presence: true, if: :failed?
  validates :transcript, presence: true, if: -> { generating? || completed? }
  validates :post, presence: true, if: :completed?

  validate :acceptable_audio

  after_update_commit :broadcast_status, if: :saved_change_to_status?

  def retryable?
    failed? && post.nil? && audio.attached?
  end

  def queue_for_retry!
    update!(status: :queued, failure_reason: nil)
  end

  def fail!(reason)
    return if completed?

    update!(status: :failed, failure_reason: reason)
  end

  private

    def acceptable_audio
      return unless audio.attached?

      content_type = audio.blob.content_type.to_s.split(";").first
      errors.add(:audio, :invalid_type) unless content_type.in?(AUDIO_CONTENT_TYPES)
      errors.add(:audio, :blank) if audio.blob.byte_size.zero?
      errors.add(:audio, :too_large) if audio.blob.byte_size > MAX_AUDIO_SIZE
    end

    def broadcast_status
      broadcast_replace_to(
        self,
        target: ActionView::RecordIdentifier.dom_id(self, :status),
        partial: "admin/post_generations/status",
        locals: { post_generation: self }
      )
    end
end
