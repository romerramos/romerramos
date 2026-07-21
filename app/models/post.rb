class Post < ApplicationRecord
  has_many :post_translations, dependent: :destroy, inverse_of: :post
  accepts_nested_attributes_for :post_translations, allow_destroy: true, reject_if: proc { |attrs| attrs["title"].blank? }

  scope :published, -> { where(published: true) }
  scope :recent_first, -> { order(published_at: :desc, created_at: :desc, id: :desc) }
  scope :translated_in, ->(locale) {
    joins(:post_translations)
      .where(post_translations: { locale: locale })
      .includes(:post_translations)
      .distinct
  }
  scope :publicly_visible_in, ->(locale) { published.translated_in(locale) }

  validate :default_translation_present

  def translation_for(locale)
    post_translations.detect { |t| t.locale == locale.to_s }
  end

  def display_translation(locale = I18n.locale)
    translation_for(locale) || translation_for(I18n.default_locale) || post_translations.first
  end

  def available_locales
    post_translations.filter_map { |translation| translation.locale if translation.title.present? }
  end

  private
    def default_translation_present
      return if translation_for(I18n.default_locale)&.title.present?

      errors.add(:post_translations, :invalid)
    end
end
