require "test_helper"

class Admin::PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @post = Post.create!(title: "First Post", description: "A short preview", content: "# Hello\n\nThis is content.", published_at: 1.day.ago)
  end

  test "should redirect unauthenticated users" do
    get admin_posts_url
    assert_redirected_to login_url
  end

  test "should get index when authenticated" do
    sign_in_as(@user)
    get admin_posts_url
    assert_response :success
  end

  test "should get show when authenticated" do
    sign_in_as(@user)
    get admin_post_url(@post)
    assert_response :success
  end

  test "should get new when authenticated" do
    sign_in_as(@user)
    get new_admin_post_url
    assert_response :success
  end

  test "should create post when authenticated" do
    sign_in_as(@user)
    assert_difference("Post.count") do
      post admin_posts_url, params: { post: { title: "New Post", description: "A preview", content: "Some content" } }
    end
    assert_redirected_to admin_post_url(Post.last)
  end

  test "should not create post with invalid data" do
    sign_in_as(@user)
    assert_no_difference("Post.count") do
      post admin_posts_url, params: { post: { title: "", description: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "should get edit when authenticated" do
    sign_in_as(@user)
    get edit_admin_post_url(@post)
    assert_response :success
  end

  test "should update post when authenticated" do
    sign_in_as(@user)
    patch admin_post_url(@post), params: { post: { title: "Updated Title" } }
    assert_redirected_to admin_post_url(@post)
    @post.reload
    assert_equal "Updated Title", @post.title
  end

  test "should not update post with invalid data" do
    sign_in_as(@user)
    patch admin_post_url(@post), params: { post: { title: "" } }
    assert_response :unprocessable_entity
  end

  test "should destroy post when authenticated" do
    sign_in_as(@user)
    assert_difference("Post.count", -1) do
      delete admin_post_url(@post)
    end
    assert_redirected_to admin_posts_url
  end
end
