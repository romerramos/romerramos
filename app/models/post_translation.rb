class PostTranslation < ApplicationRecord
  belongs_to :post, inverse_of: :post_translations

  attribute :published, :boolean, default: false

  scope :published, -> { where(published: true) }
  scope :spanish_drafts, -> { where(locale: "es", published: false) }
  scope :pending_spanish_draft_regeneration, -> {
    spanish_drafts.where(spanish_draft_regenerated_at: nil)
  }

  validates :locale, presence: true, inclusion: { in: -> { I18n.available_locales.map(&:to_s) } }
  validates :title, :content, presence: true, if: :published?
  validates :locale, uniqueness: { scope: :post_id, message: "translation already exists for this locale" }

  before_validation :set_published_at, if: :published?

  private
    def set_published_at
      self.published_at ||= Time.current
    end
end
