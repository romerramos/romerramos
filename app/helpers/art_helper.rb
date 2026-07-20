module ArtHelper
  def photo_aspect_ratio(photo)
    width = photo.image.metadata["width"]
    height = photo.image.metadata["height"]

    width.present? && height.present? ? "#{width} / #{height}" : "1 / 1"
  end
end
