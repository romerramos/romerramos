require "test_helper"
require "stringio"

class Admin::PostGenerationsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:one)
  end

  test "requires authentication" do
    get new_admin_post_generation_url

    assert_redirected_to login_url
  end

  test "new renders the recording form" do
    sign_in_as(@user)

    get new_admin_post_generation_url

    assert_response :success
    assert_select "form[enctype='multipart/form-data']"
    assert_select "select[name='post_generation[source_locale]']"
    assert_select "input[type='file'][name='post_generation[audio]']"
    assert_select "[data-controller='admin--post-recording']"
  end

  test "show renders the current processing status" do
    generation = create_generation
    sign_in_as(@user)

    get admin_post_generation_url(generation)

    assert_response :success
    assert_select "##{ActionView::RecordIdentifier.dom_id(generation, :status)}"
    assert_select "p", /Waiting to start/
  end

  test "show links to the post editor once generation is complete" do
    post = Post.create!(
      post_translations_attributes: [
        { locale: "en", title: "English", content: "English content" },
        { locale: "es", title: "Spanish", content: "Spanish content" }
      ]
    )
    generation = @user.post_generations.new(
      source_locale: "en",
      status: :completed,
      transcript: "Transcript",
      post: post
    )
    generation.audio.attach(
      io: StringIO.new("audio"),
      filename: "recording.webm",
      content_type: "audio/webm"
    )
    generation.save!

    sign_in_as(@user)
    get admin_post_generation_url(generation)

    assert_response :success
    assert_select "[data-controller='admin--post-generation-redirect']"
    assert_select "a[href='#{edit_admin_post_path(post)}']"
  end

  test "create stores the recording and enqueues generation" do
    sign_in_as(@user)

    assert_difference "PostGeneration.count", 1 do
      assert_enqueued_with job: PostGenerationJob do
        post admin_post_generations_url, params: {
          post_generation: {
            source_locale: "es",
            audio: uploaded_audio
          }
        }
      end
    end

    generation = PostGeneration.order(:id).last
    assert_redirected_to admin_post_generation_url(generation)
    assert_equal "es", generation.source_locale
    assert generation.audio.attached?
  end

  test "create renders validation errors without enqueueing" do
    sign_in_as(@user)

    assert_no_enqueued_jobs do
      post admin_post_generations_url, params: {
        post_generation: { source_locale: "en" }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']"
  end

  test "users cannot view another user's generation" do
    other_generation = users(:two).post_generations.new(source_locale: "en")
    other_generation.audio.attach(
      io: StringIO.new("audio"),
      filename: "recording.webm",
      content_type: "audio/webm"
    )
    other_generation.save!

    sign_in_as(@user)
    get admin_post_generation_url(other_generation)

    assert_response :not_found
  end

  test "failed generations can be queued again" do
    generation = users(:one).post_generations.new(
      source_locale: "en",
      status: :failed,
      failure_reason: "unexpected"
    )
    generation.audio.attach(
      io: StringIO.new("audio"),
      filename: "recording.webm",
      content_type: "audio/webm"
    )
    generation.save!

    sign_in_as(@user)

    assert_enqueued_with job: PostGenerationJob do
      patch admin_post_generation_url(generation)
    end

    assert_redirected_to admin_post_generation_url(generation)
    assert generation.reload.queued?
  end

  private

    def create_generation
      generation = @user.post_generations.new(source_locale: "en")
      generation.audio.attach(
        io: StringIO.new("audio"),
        filename: "recording.webm",
        content_type: "audio/webm"
      )
      generation.save!
      generation
    end

    def uploaded_audio
      Rack::Test::UploadedFile.new(
        StringIO.new("audio"),
        "audio/webm",
        original_filename: "recording.webm"
      )
    end
end
