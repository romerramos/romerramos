require "test_helper"

class ArtControllerTest < ActionDispatch::IntegrationTest
  setup do
    @published = Photo.create!(title_en: "Visible", image: sample_image)
    @hidden = Photo.create!(title_en: "Hidden", published: false, image: sample_image)
  end

  test "index renders the gallery" do
    get art_path(locale: :en)

    assert_response :success
    assert_select "[data-controller=\"lightbox\"]"
    assert_select "img[style=\"aspect-ratio: 1 / 1\"]"
  end

  test "index only shows published photos" do
    get art_path(locale: :en)

    assert_select ".art-photo", count: 1
  end

  test "index works in spanish" do
    get art_path(locale: :es)

    assert_response :success
  end

  private
    def sample_image
      fixture_file_upload("sample.jpg", "image/jpeg")
    end
end
