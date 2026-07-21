class Post < ApplicationRecord
  has_many :post_translations, dependent: :destroy, inverse_of: :post
  accepts_nested_attributes_for :post_translations, allow_destroy: true, reject_if: :blank_translation?

  scope :published, -> { where(published: true) }
  scope :recent_first, -> { order(published_at: :desc, created_at: :desc, id: :desc) }
  scope :translated_in, ->(locale) {
    joins(:post_translations)
      .where(post_translations: { locale: locale })
      .includes(:post_translations)
  }
  scope :publicly_visible_in, ->(locale) {
    joins(:post_translations)
      .where(post_translations: { locale: locale, published: true })
      .includes(:post_translations)
      .order("post_translations.published_at DESC", created_at: :desc, id: :desc)
  }

  validate :default_translation_present

  def post_translation_for(locale)
    post_translations.find { |translation| translation.locale == locale.to_s } ||
      post_translations.find { |translation| translation.locale == I18n.default_locale.to_s } ||
      post_translations.first
  end

  def available_locales
    post_translations.filter_map { |translation| translation.locale if translation.title.present? }
  end

  def published_locales
    post_translations.filter_map { |translation| translation.locale if translation.published? }
  end

  private
    def blank_translation?(attributes)
      !PostTranslation.type_for_attribute("published").cast(attributes["published"]) &&
        attributes.values_at("title", "description", "content").all?(&:blank?)
    end

    def default_translation_present
      translation = post_translations.find { |item| item.locale == I18n.default_locale.to_s }
      return if translation && !translation.marked_for_destruction?

      errors.add(:post_translations, :invalid)
    end
end
