require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "should be valid with title and description" do
    post = Post.new(title: "Hello", description: "A short preview")
    assert post.valid?
  end

  test "should be invalid without title" do
    post = Post.new(description: "A short preview")
    assert_not post.valid?
    assert_includes post.errors[:title], "can't be blank"
  end

  test "should be invalid without description" do
    post = Post.new(title: "Hello")
    assert_not post.valid?
    assert_includes post.errors[:description], "can't be blank"
  end
end
