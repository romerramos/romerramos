class Photo < ApplicationRecord
  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 800, nil ]
    attachable.variant :large, resize_to_limit: [ 2000, 2000 ]
  end

  scope :published, -> { where(published: true) }

  default_scope -> { order(:position, :id) }

  validates :image, presence: true
  validate :acceptable_image

  before_validation :assign_position, on: :create

  # Locale-aware readers that fall back to whichever locale has content.
  def display_title
    localized(:title)
  end

  def display_caption
    localized(:caption)
  end

  # CSS `aspect-ratio` value (e.g. "3 / 2") so the masonry grid reserves space
  # before the image loads. Falls back to a neutral 1/1 when dimensions are unknown.
  def aspect_ratio
    return "1 / 1" unless image.attached?

    image.analyze unless image.analyzed?
    width  = image.metadata["width"]
    height = image.metadata["height"]
    return "1 / 1" if width.blank? || height.blank?

    "#{width} / #{height}"
  end

  private
    def localized(attr)
      public_send("#{attr}_#{I18n.locale}").presence ||
        public_send("#{attr}_en").presence ||
        public_send("#{attr}_es").presence
    end

    def assign_position
      self.position ||= (self.class.unscoped.maximum(:position) || 0) + 1
    end

    def acceptable_image
      return unless image.attached?

      unless image.blob.content_type.in?(%w[image/png image/jpeg image/webp image/gif])
        errors.add(:image, :invalid_type)
      end

      if image.blob.byte_size > 20.megabytes
        errors.add(:image, :too_large)
      end
    end
end
