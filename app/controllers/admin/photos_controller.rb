module Admin
  class PhotosController < Admin::BaseController
    before_action :set_photo, only: %i[edit update destroy]

    def index
      @photos = Photo.with_attached_image
    end

    def new
      @photo = Photo.new
    end

    def create
      images = Array(params.dig(:photo, :images)).reject(&:blank?)

      if images.empty?
        @photo = Photo.new
        @photo.errors.add(:image, :blank)
        return render :new, status: :unprocessable_entity
      end

      created = images.map do |image|
        photo = Photo.new(image: image)
        photo.tap { |p| p.save }
      end

      if created.all?(&:persisted?)
        redirect_to admin_photos_path, notice: t("admin.photos.created")
      else
        @photo = created.find { |p| !p.persisted? } || Photo.new
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @photo.update(photo_params)
        redirect_to admin_photos_path, notice: t("admin.photos.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @photo.destroy
      redirect_to admin_photos_path, notice: t("admin.photos.destroyed")
    end

    def reorder
      Photo.transaction do
        Array(params[:ids]).each_with_index do |id, index|
          Photo.where(id: id).update_all(position: index + 1)
        end
      end
      head :no_content
    end

    private
      def set_photo
        @photo = Photo.find(params[:id])
      end

      def photo_params
        params.require(:photo).permit(
          :title_en, :title_es, :caption_en, :caption_es, :published, :image
        )
      end
  end
end
