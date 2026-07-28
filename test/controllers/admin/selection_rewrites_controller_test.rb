require "test_helper"

class Admin::SelectionRewritesControllerTest < ActionDispatch::IntegrationTest
  class FakeAdapter
    def generate(_input, instructions:, schema:, effort: :high)
      Struct.new(:content).new({ "rewritten" => "REWRITTEN" })
    end
  end

  setup do
    @user = users(:one)
    @post = create_post
    @english = @post.post_translation_for(:en)
    @spanish = @post.post_translation_for(:es)
  end

  test "requires authentication" do
    post admin_post_selection_rewrite_url(@post), params: rewrite_params

    assert_redirected_to login_url
  end

  test "returns the rewritten selection without persisting it" do
    sign_in_as(@user)

    with_adapter do
      post admin_post_selection_rewrite_url(@post), params: rewrite_params, as: :turbo_stream
    end

    assert_response :success
    assert_match "Keep this. REWRITTEN Keep that too.", @response.body
    assert_equal "Keep this. Rewrite me. Keep that too.", @english.reload.content
  end

  test "swaps only the rewritten locale's editor so the rest of the page is untouched" do
    sign_in_as(@user)

    with_adapter do
      post admin_post_selection_rewrite_url(@post), params: rewrite_params, as: :turbo_stream
    end

    assert_match %r{<turbo-stream action="update" target="editor_en">}, @response.body
    assert_no_match "editor_es", @response.body
    assert_no_match "Contenido en español.", @response.body
    assert_no_match "data-tabs-target", @response.body
  end

  test "swapped field keeps the nested attribute name the form submits under" do
    sign_in_as(@user)
    params = rewrite_params
    params[:selection_rewrite][:locale] = "es"
    params[:selection_rewrite][:selection] = "español"
    params[:selection_rewrite][:selection_start] = 13
    params[:selection_rewrite][:selection_end] = 20

    with_adapter do
      post admin_post_selection_rewrite_url(@post), params: params, as: :turbo_stream
    end

    assert_match %r{<turbo-stream action="update" target="editor_es">}, @response.body
    assert_match "post[post_translations_attributes][1][content]", @response.body
    assert_match "Contenido en REWRITTEN.", @response.body
  end

  test "rewrites a whole language when the selection spans the entire content" do
    sign_in_as(@user)
    params = rewrite_params
    params[:selection_rewrite][:selection] = @english.content
    params[:selection_rewrite][:selection_start] = 0
    params[:selection_rewrite][:selection_end] = @english.content.length

    with_adapter do
      post admin_post_selection_rewrite_url(@post), params: params, as: :turbo_stream
    end

    assert_match %r{<turbo-stream action="update" target="editor_en">}, @response.body
    assert_match "REWRITTEN</textarea>", @response.body # the whole field, not a splice
    assert_equal "Keep this. Rewrite me. Keep that too.", @english.reload.content
  end

  test "redirects with an alert when the selection no longer matches" do
    sign_in_as(@user)
    params = rewrite_params
    params[:selection_rewrite][:selection] = "Text that is not there"

    with_adapter do
      post admin_post_selection_rewrite_url(@post), params: params
    end

    assert_redirected_to edit_admin_post_url(@post)
    assert_equal I18n.t("admin.posts.selection_rewrite.stale"), flash[:alert]
    assert_equal "Keep this. Rewrite me. Keep that too.", @english.reload.content
  end

  private

    def rewrite_params
      {
        post: {
          post_translations_attributes: {
            "0" => { id: @english.id, locale: "en", title: @english.title, description: @english.description, content: @english.content, published: "1" },
            "1" => { id: @spanish.id, locale: "es", title: @spanish.title, description: @spanish.description, content: @spanish.content, published: "0" }
          }
        },
        selection_rewrite: {
          locale: "en",
          selection: "Rewrite me.",
          selection_start: 11,
          selection_end: 22
        }
      }
    end

    def with_adapter
      original_new = PostGenerations::Adapter.method(:new)
      PostGenerations::Adapter.define_singleton_method(:new) { FakeAdapter.new }
      yield
    ensure
      PostGenerations::Adapter.define_singleton_method(:new) { original_new.call }
    end

    def create_post
      Post.create!(
        post_translations_attributes: {
          "0" => { locale: "en", title: "First Post", description: "A preview", content: "Keep this. Rewrite me. Keep that too." },
          "1" => { locale: "es", title: "Primer Post", description: "Una vista previa", content: "Contenido en español." }
        }
      )
    end
end
