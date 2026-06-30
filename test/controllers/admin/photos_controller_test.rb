require "test_helper"

class Admin::PhotosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.take
    @photo = Photo.create!(title_en: "One", image: sample_image)
  end

  test "requires authentication" do
    get admin_photos_path
    assert_redirected_to login_path(locale: :en)
  end

  test "index lists photos when signed in" do
    sign_in_as(@user)
    get admin_photos_path

    assert_response :success
    assert_select "[data-controller=\"sortable\"]"
  end

  test "new renders" do
    sign_in_as(@user)
    get new_admin_photo_path
    assert_response :success
  end

  test "create adds one photo per uploaded file" do
    sign_in_as(@user)

    assert_difference -> { Photo.count }, 2 do
      post admin_photos_path, params: { photo: { images: [ sample_image, sample_image ] } }
    end

    assert_redirected_to admin_photos_path(locale: :en)
  end

  test "create without an image is rejected" do
    sign_in_as(@user)

    assert_no_difference -> { Photo.count } do
      post admin_photos_path, params: { photo: { images: [] } }
    end

    assert_response :unprocessable_entity
  end

  test "update changes localized fields and published flag" do
    sign_in_as(@user)

    patch admin_photo_path(@photo), params: {
      photo: { title_es: "Uno", caption_en: "A caption", published: "0" }
    }

    assert_redirected_to admin_photos_path(locale: :en)
    @photo.reload
    assert_equal "Uno", @photo.title_es
    assert_equal "A caption", @photo.caption_en
    assert_not @photo.published?
  end

  test "destroy removes the photo" do
    sign_in_as(@user)

    assert_difference -> { Photo.count }, -1 do
      delete admin_photo_path(@photo)
    end

    assert_redirected_to admin_photos_path(locale: :en)
  end

  test "reorder persists the new positions" do
    sign_in_as(@user)
    second = Photo.create!(title_en: "Two", image: sample_image)

    patch reorder_admin_photos_path, params: { ids: [ second.id, @photo.id ] }, as: :json

    assert_response :no_content
    assert_equal 1, second.reload.position
    assert_equal 2, @photo.reload.position
  end

  private
    def sample_image
      fixture_file_upload("sample.jpg", "image/jpeg")
    end
end
