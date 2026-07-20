class ArtController < PublicController
  def index
    @photos = Photo.published.ordered.with_attached_image
  end
end
