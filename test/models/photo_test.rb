require "test_helper"

class PhotoTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile

  test "maintains unique sequential positions" do
    first = create_photo("One")
    second = create_photo("Two")

    second.update!(position: 1)

    assert_equal [ second.id, first.id ], Photo.ordered.pluck(:id)
    assert_equal [ 1, 2 ], Photo.ordered.pluck(:position)
  end

  test "closes the position gap when a photo is deleted" do
    first = create_photo("One")
    second = create_photo("Two")

    first.destroy!

    assert_equal 1, second.reload.position
  end

  private
    def create_photo(title)
      Photo.create!(title_en: title, image: fixture_file_upload("sample.jpg", "image/jpeg"))
    end
end
