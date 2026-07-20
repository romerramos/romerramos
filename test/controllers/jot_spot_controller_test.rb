require "test_helper"

class JotSpotControllerTest < ActionDispatch::IntegrationTest
  test "shows only published posts translated in the requested locale" do
    published = create_post("Visible", published_at: 1.day.ago)
    create_post("Draft")
    create_post("Scheduled", published_at: 1.day.from_now)
    create_post("English only", published_at: 1.day.ago, spanish: false)

    get jot_spot_path(locale: :es)

    assert_response :success
    assert_select "h1", text: published.translation_for(:es).title
    assert_select "h1", text: "Draft", count: 0
    assert_select "h1", text: "Scheduled", count: 0
    assert_select "h1", text: "English only", count: 0
  end

  private
    def create_post(title, published_at: nil, spanish: true)
      translations = {
        "0" => { locale: "en", title: title, description: "English description", content: "English body" }
      }
      if spanish
        translations["1"] = { locale: "es", title: "#{title} ES", description: "Descripción", content: "Contenido" }
      end

      Post.create!(published_at: published_at, post_translations_attributes: translations)
    end
end
