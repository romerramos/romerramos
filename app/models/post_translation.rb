class PostTranslation < ApplicationRecord
  belongs_to :post, inverse_of: :post_translations

  validates :locale, presence: true, inclusion: { in: -> { I18n.available_locales.map(&:to_s) } }
  validates :title, presence: true
  validates :locale, uniqueness: { scope: :post_id, message: "translation already exists for this locale" }
end
