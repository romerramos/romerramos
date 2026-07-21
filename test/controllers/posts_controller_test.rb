require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  test "index shows localized published post previews without their bodies" do
    published = create_post("Visible", published: true, published_at: 1.day.ago)
    immediate = create_post("Immediate", published: true)
    create_post("Draft", published: false)
    future_dated = create_post("Future dated", published: true, published_at: 1.day.from_now)
    create_post("English only", published: true, spanish: false)

    get posts_path(locale: :es)

    assert_response :success
    assert_select "h1", text: I18n.t("posts.heading", locale: :es), count: 1
    assert_select "h2", text: published.translation_for(:es).title
    assert_select "h2", text: immediate.translation_for(:es).title
    assert_select "h2", text: "Future dated ES"
    assert_select "h2", text: "Draft", count: 0
    assert_select "h2", text: "English only", count: 0
    assert_select "p", text: "Descripción"
    assert_select "article.prose", count: 0
    assert_select "a[href=?]", post_path(published, locale: :es)
  end

  test "index paginates posts" do
    11.times { |number| create_post("Post #{number}", published: true, published_at: number.days.ago) }

    get posts_path(locale: :en)

    assert_response :success
    assert_select "h2", count: 10
    assert_select "nav[aria-label=?]", I18n.t("posts.pagination", locale: :en)
  end

  test "show renders a localized published post and a link back to the index" do
    post = create_post("Visible", published: true)

    get post_path(post, locale: :es)

    assert_response :success
    assert_select "h1", text: "Visible ES"
    assert_select "article.prose", text: /Contenido/
    assert_select "a[href=?]", posts_path(locale: :es), text: I18n.t("posts.back", locale: :es)
    assert_select "title", text: /Visible ES/
  end

  test "show does not expose drafts or posts missing the requested translation" do
    draft = create_post("Draft")
    english_only = create_post("English only", published: true, spanish: false)

    get post_path(draft, locale: :en)
    assert_response :not_found

    get post_path(english_only, locale: :es)
    assert_response :not_found
  end

  private
    def create_post(title, published: false, published_at: nil, spanish: true)
      translations = {
        "0" => { locale: "en", title: title, description: "English description", content: "English body" }
      }
      if spanish
        translations["1"] = { locale: "es", title: "#{title} ES", description: "Descripción", content: "Contenido" }
      end

      Post.create!(published: published, published_at: published_at, post_translations_attributes: translations)
    end
end
