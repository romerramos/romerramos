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
      build_missing_translations
    end

    def create
      @post = Post.new(post_params)

      if @post.save
        redirect_to admin_post_path(@post), notice: t("admin.posts.created")
      else
        build_missing_translations
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      build_missing_translations
    end

    def update
      if @post.update(post_params)
        redirect_to admin_post_path(@post), notice: t("admin.posts.updated")
      else
        build_missing_translations
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

      def build_missing_translations
        existing_locales = @post.post_translations.map(&:locale)
        I18n.available_locales.each do |locale|
          @post.post_translations.build(locale: locale.to_s) unless locale.to_s.in?(existing_locales)
        end
      end
  end
end
