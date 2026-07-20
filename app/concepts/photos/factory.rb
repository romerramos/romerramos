module Photos
  class Factory
    attr_reader :photos

    def initialize(images:)
      @photos = images.map { |image| Photo.new(image: image) }
    end

    def create
      return false unless photos.all?(&:valid?)

      Photo.transaction { photos.each(&:save!) }
      true
    end

    def invalid_photo
      photos.find(&:invalid?)
    end
  end
end
