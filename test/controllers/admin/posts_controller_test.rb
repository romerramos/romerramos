require "test_helper"

class Admin::PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @post = create_post
  end

  test "requires authentication" do
    get admin_posts_url

    assert_redirected_to login_url
  end

  test "index renders when authenticated" do
    sign_in_as(@user)

    get admin_posts_url

    assert_response :success
  end

  test "show renders when authenticated" do
    sign_in_as(@user)

    get admin_post_url(@post)

    assert_response :success
  end

  test "new renders fields for every locale" do
    sign_in_as(@user)

    get new_admin_post_url

    assert_response :success
    assert_select "input[name*='[post_translations_attributes]'][name$='[locale]']", count: I18n.available_locales.count
    assert_select "input[type='checkbox'][name*='[post_translations_attributes]'][name$='[published]']", count: I18n.available_locales.count
    assert_select "input[name*='[post_translations_attributes]'][name$='[published_at]']", count: I18n.available_locales.count
  end

  test "create saves publication and all translated fields together" do
    sign_in_as(@user)
    published_at = 1.day.ago.change(usec: 0)

    assert_difference([ "Post.count", "PostTranslation.count" ], 1) do
      post admin_posts_url, params: {
        post: {
          post_translations_attributes: {
            "0" => {
              locale: "en",
              title: "New Post",
              description: "A preview",
              content: "# Some content",
              published: "1",
              published_at: published_at
            }
          }
        }
      }
    end

    created = Post.order(:id).last
    assert_redirected_to admin_post_url(created)
    assert created.post_translation_for(:en).published?
    assert_equal published_at, created.post_translation_for(:en).published_at
    assert_equal "# Some content", created.post_translation_for(:en).content
  end

  test "create interprets publication dates in Madrid time" do
    sign_in_as(@user)

    post admin_posts_url, params: {
      post: {
          post_translations_attributes: {
            "0" => { locale: "en", title: "Madrid Post", content: "Body", published: "1", published_at: "2026-07-20T18:00" }
        }
      }
    }

    created = Post.order(:id).last
    assert_equal Time.zone.local(2026, 7, 20, 18), created.post_translation_for(:en).published_at
    assert_equal Time.utc(2026, 7, 20, 16), created.post_translation_for(:en).published_at.utc
  end

  test "create saves multiple translations together" do
    sign_in_as(@user)

    assert_difference -> { PostTranslation.count }, 2 do
      post admin_posts_url, params: {
        post: {
          post_translations_attributes: {
            "0" => { locale: "en", title: "Hello", description: "Summary", content: "Body" },
            "1" => { locale: "es", title: "Hola", description: "Resumen", content: "Contenido" }
          }
        }
      }
    end

    assert_equal %w[en es], Post.order(:id).last.available_locales.sort
  end

  test "create can publish one translation while keeping another as a draft" do
    sign_in_as(@user)

    post admin_posts_url, params: {
      post: {
        post_translations_attributes: {
          "0" => { locale: "en", title: "Ready", content: "English body", published: "1" },
          "1" => { locale: "es", title: "En progreso", content: "", published: "0" }
        }
      }
    }

    created = Post.order(:id).last
    assert created.post_translation_for(:en).published?
    assert_not created.post_translation_for(:es).published?
  end

  test "create rejects a missing default translation" do
    sign_in_as(@user)

    assert_no_difference "Post.count" do
      post admin_posts_url, params: {
        post: { post_translations_attributes: { "0" => { locale: "es", title: "Hola" } } }
      }
    end

    assert_response :unprocessable_entity
  end

  test "edit renders when authenticated" do
    sign_in_as(@user)

    get edit_admin_post_url(@post)

    assert_response :success
  end

  test "update changes publication and translated fields independently" do
    sign_in_as(@user)
    translation = @post.post_translation_for(:en)
    published_at = 2.days.ago.change(usec: 0)

    patch admin_post_url(@post), params: {
      post: {
        post_translations_attributes: {
          "0" => { id: translation.id, locale: "en", title: "Updated", description: "Updated preview", content: "Updated body", published: "0", published_at: published_at }
        }
      }
    }

    assert_redirected_to admin_post_url(@post)
    @post.reload
    assert_not @post.post_translation_for(:en).published?
    assert_equal published_at, @post.post_translation_for(:en).published_at
    assert_equal "Updated body", @post.post_translation_for(:en).content
  end

  test "update rejects removing the default translation" do
    sign_in_as(@user)
    translation = @post.post_translation_for(:en)

    patch admin_post_url(@post), params: {
      post: {
        post_translations_attributes: {
          "0" => { id: translation.id, locale: "en", title: "", _destroy: "1" }
        }
      }
    }

    assert_response :unprocessable_entity
    assert @post.reload.post_translation_for(:en)
  end

  test "destroy removes the post and translations" do
    sign_in_as(@user)

    assert_difference([ "Post.count", "PostTranslation.count" ], -1) do
      delete admin_post_url(@post)
    end

    assert_redirected_to admin_posts_url
  end

  private
    def create_post
      Post.create!(
        post_translations_attributes: {
          "0" => { locale: "en", title: "First Post", description: "A preview", content: "# Hello", published: true, published_at: 1.day.ago }
        }
      )
    end
end
