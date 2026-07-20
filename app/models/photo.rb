class Photo < ApplicationRecord
  MAX_IMAGE_SIZE = 100.megabytes

  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 800, nil ]
    attachable.variant :large, resize_to_limit: [ 2000, 2000 ]
  end

  scope :published, -> { where(published: true) }
  scope :ordered, -> { order(:position, :id) }

  positioned

  validates :image, presence: true
  validate :acceptable_image

  # Locale-aware readers that fall back to whichever locale has content.
  def display_title
    localized(:title)
  end

  def display_caption
    localized(:caption)
  end

  private
    def localized(attr)
      public_send("#{attr}_#{I18n.locale}").presence ||
        public_send("#{attr}_en").presence ||
        public_send("#{attr}_es").presence
    end

    def acceptable_image
      return unless image.attached?

      unless image.blob.content_type.in?(%w[image/png image/jpeg image/webp image/gif])
        errors.add(:image, :invalid_type)
      end

      if image.blob.byte_size > MAX_IMAGE_SIZE
        errors.add(:image, :too_large)
      end
    end
end
