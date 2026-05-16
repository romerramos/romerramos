module Admin
  class PostsController < BaseController
    before_action :set_post, only: %i[ show edit update destroy ]

    def index
      @posts = Post.order(created_at: :desc).includes(:post_translations)
    end

    def show
    end

    def new
      @post = Post.new
      @post.post_translations.build(locale: "en")
    end

    def create
      @post = Post.new(post_params)

      if @post.save
        redirect_to admin_post_path(@post), notice: "Post created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      I18n.available_locales.each do |locale|
        unless @post.post_translations.exists?(locale: locale.to_s)
          @post.post_translations.build(locale: locale.to_s)
        end
      end
    end

    def update
      if @post.update(post_params)
        redirect_to admin_post_path(@post), notice: "Post updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @post.destroy
      redirect_to admin_posts_path, notice: "Post deleted successfully.", status: :see_other
    end

    private

      def set_post
        @post = Post.includes(:post_translations).find(params[:id])
      end

      def post_params
        params.require(:post).permit(
          :published_at,
          post_translations_attributes: [ :id, :locale, :title, :description, :content, :_destroy ]
        )
      end
  end
end