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
      post_translations_attributes: {
        "0" => { locale: "en", title: "Hello", description: "Summary", content: "# Body" },
        "1" => { locale: "es", title: "Hola", description: "Resumen", content: "# Contenido" }
      }
    )

    assert_equal %w[en es], post.available_locales.sort
    assert_equal "Resumen", post.post_translation_for(:es).description
    assert_equal "# Body", post.post_translation_for(:en).content
  end

  test "falls back to the default post translation" do
    post = build_post

    assert_equal "Hello", post.post_translation_for(:es).title
  end

  test "publicly visible includes posts published in the requested locale" do
    published = create_post("Published", published: true)

    assert_equal [ published ], Post.publicly_visible_in(:en).to_a
  end

  test "publicly visible excludes drafts and includes posts regardless of date" do
    published = create_post("Published", published: true, published_at: 1.day.ago)
    future_dated = create_post("Future dated", published: true, published_at: 1.day.from_now)
    create_post("Draft", published: false)

    assert_equal [ published, future_dated ], Post.publicly_visible_in(:en).reorder(:id).to_a
  end

  test "a published translation remains visible when its date changes" do
    post = create_post("Published", published: true)

    post.post_translation_for(:en).update!(published_at: 1.day.ago)

    assert_includes Post.publicly_visible_in(:en), post
  end

  test "draft translations may be incomplete" do
    post = Post.new(post_translations_attributes: {
      "0" => { locale: "en", content: "Work in progress" }
    })

    assert post.valid?
  end

  test "published translations require title and content" do
    post = Post.new(post_translations_attributes: {
      "0" => { locale: "en", published: true }
    })

    assert_not post.valid?
    assert post.post_translation_for(:en).errors.added?(:title, :blank)
    assert post.post_translation_for(:en).errors.added?(:content, :blank)
  end

  test "publishing assigns a publication date" do
    post = create_post("Published", published: true)

    assert_in_delta Time.current, post.post_translation_for(:en).published_at, 1.second
  end

  private
    def build_post(title = "Hello", published: false, published_at: nil)
      Post.new(
        post_translations_attributes: {
          "0" => { locale: "en", title: title, description: "A short preview", content: "# Content", published: published, published_at: published_at }
        }
      )
    end

    def create_post(title, published: false, published_at: nil)
      build_post(title, published: published, published_at: published_at).tap(&:save!)
    end
end
