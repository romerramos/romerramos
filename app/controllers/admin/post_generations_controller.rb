module Admin
  class PostGenerationsController < BaseController
    before_action :set_post_generation, only: %i[ show update ]

    def new
      @post_generation = Current.user.post_generations.new(
        source_locale: I18n.default_locale
      )
    end

    def create
      @post_generation = Current.user.post_generations.new(post_generation_params)

      if @post_generation.save
        PostGenerationJob.perform_later(@post_generation)
        redirect_to admin_post_generation_path(@post_generation)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
    end

    def update
      if @post_generation.retryable?
        @post_generation.queue_for_retry!
        PostGenerationJob.perform_later(@post_generation)
        redirect_to admin_post_generation_path(@post_generation)
      else
        redirect_to admin_post_generation_path(@post_generation),
          alert: t("admin.post_generations.not_retryable")
      end
    end

    private

      def set_post_generation
        @post_generation = Current.user.post_generations.find(params[:id])
      end

      def post_generation_params
        params.require(:post_generation).permit(:source_locale, :audio)
      end
  end
end
