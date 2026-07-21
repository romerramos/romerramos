require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "is valid with a default translation" do
    post = build_post

    assert post.valid?
  end

  test "requires a default locale translation" do
    post = Post.new(post_translations_attributes: {
      "0" => { locale: "es", title: "Hola" }
    })

    assert_not post.valid?
    assert post.errors.added?(:post_translations, :invalid)
  end

  test "accepts multiple translated fields in one post" do
    post = Post.create!(
      published_at: 1.day.ago,
      post_translations_attributes: {
        "0" => { locale: "en", title: "Hello", description: "Summary", content: "# Body" },
        "1" => { locale: "es", title: "Hola", description: "Resumen", content: "# Contenido" }
      }
    )

    assert_equal %w[en es], post.available_locales.sort
    assert_equal "Resumen", post.translation_for(:es).description
    assert_equal "# Body", post.translation_for(:en).content
  end

  test "falls back to the default translation for display" do
    post = build_post

    assert_equal "Hello", post.display_translation(:es).title
  end

  test "published includes explicitly published posts without a date" do
    published = create_post("Published", published: true)

    assert_equal [ published ], Post.published.to_a
  end

  test "published excludes drafts and includes posts regardless of date" do
    published = create_post("Published", published: true, published_at: 1.day.ago)
    future_dated = create_post("Future dated", published: true, published_at: 1.day.from_now)
    create_post("Draft", published: false)

    assert_equal [ published, future_dated ], Post.published.order(:id).to_a
  end

  test "a published post remains visible when its date changes" do
    post = create_post("Published", published: true)

    post.update!(published_at: 1.day.ago)

    assert_includes Post.published, post
  end

  private
    def build_post(title = "Hello", published: false, published_at: nil)
      Post.new(
        published: published,
        published_at: published_at,
        post_translations_attributes: {
          "0" => { locale: "en", title: title, description: "A short preview", content: "# Content" }
        }
      )
    end

    def create_post(title, published: false, published_at: nil)
      build_post(title, published: published, published_at: published_at).tap(&:save!)
    end
end
