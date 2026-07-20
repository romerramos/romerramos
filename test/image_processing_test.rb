require "test_helper"

class ImageProcessingTest < ActiveSupport::TestCase
  test "Active Storage uses a working Vips processor" do
    assert_equal :vips, Rails.application.config.active_storage.variant_processor

    processed = ImageProcessing::Vips
      .source(Rails.root.join("app/assets/images/me.jpg").to_s)
      .resize_to_limit(16, 16)
      .call

    assert_operator processed.size, :>, 0
  ensure
    processed&.close!
  end
end
