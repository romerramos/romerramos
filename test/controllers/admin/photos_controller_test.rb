require "test_helper"

class Admin::PhotosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.take
    @photo = Photo.create!(title_en: "One", image: sample_image)
  end

  test "requires authentication" do
    get admin_photos_path
    assert_redirected_to login_path
  end

  test "admin root points to post management" do
    get "/admin"

    assert_redirected_to admin_posts_path
  end

  test "index lists photos when signed in" do
    sign_in_as(@user)
    get admin_photos_path

    assert_response :success
    assert_select "[data-controller=\"admin--photo-reorder\"]"
    assert_select "[data-controller=\"admin--photo-reorder\"] > div", count: Photo.count do
      assert_select "form[data-admin--photo-reorder-form] input[name=\"photo[position]\"]", count: 1
    end
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

    assert_redirected_to admin_photos_path
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

    assert_redirected_to admin_photos_path
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

    assert_redirected_to admin_photos_path
  end

  test "position update persists the new position" do
    sign_in_as(@user)
    second = Photo.create!(title_en: "Two", image: sample_image)

    patch admin_photo_path(second), params: { photo: { position: 1 } }

    assert_redirected_to admin_photos_path
    assert_equal 1, second.reload.position
    assert_equal 2, @photo.reload.position
  end

  test "failed batch uploads do not create photos" do
    sign_in_as(@user)
    invalid_image = fixture_file_upload("invalid.txt", "text/plain")

    assert_no_difference -> { Photo.count } do
      post admin_photos_path, params: { photo: { images: [ sample_image, invalid_image ] } }
    end

    assert_response :unprocessable_entity
  end

  private
    def sample_image
      fixture_file_upload("sample.jpg", "image/jpeg")
    end
end
