class Post < ApplicationRecord
  has_many :post_translations, dependent: :destroy, inverse_of: :post
  accepts_nested_attributes_for :post_translations, allow_destroy: true, reject_if: proc { |attrs| attrs["title"].blank? }

  validates :post_translations, presence: true

  def translation_for(locale)
    post_translations.detect { |t| t.locale == locale.to_s }
  end

  def available_locales
    post_translations.map(&:locale)
  end

  def has_translation?(locale)
    post_translations.any? { |t| t.locale == locale.to_s }
  end

  def default_translation
    post_translations.first
  end
end