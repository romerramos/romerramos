class ArtController < PublicController
  def index
    @photos = Photo.published.with_attached_image
  end
end
