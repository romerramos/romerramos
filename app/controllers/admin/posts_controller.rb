module Admin
  class PostsController < BaseController
    before_action :set_post, only: %i[ show edit update destroy ]

    def index
      @posts = Post.recent_first.includes(:post_translations)
    end

    def show
    end

    def new
      @post = Post.new
      @post.build_missing_translations
    end

    def create
      @post = Post.new(post_params)

      if @post.save
        redirect_to admin_post_path(@post), notice: t("admin.posts.created")
      else
        @post.build_missing_translations
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @post.build_missing_translations
    end

    def update
      if @post.update(post_params)
        redirect_to admin_post_path(@post), notice: t("admin.posts.updated")
      else
        @post.build_missing_translations
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @post.destroy!
      redirect_to admin_posts_path, notice: t("admin.posts.destroyed"), status: :see_other
    end

    private

      def set_post
        @post = Post.includes(:post_translations).find(params[:id])
      end

      def post_params
        params.require(:post).permit(
          post_translations_attributes: [ :id, :locale, :title, :description, :content, :published, :published_at, :_destroy ]
        )
      end
  end
end
