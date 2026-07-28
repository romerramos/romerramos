module Admin
  class SelectionRewritesController < BaseController
    def create
      @post = Post.includes(:post_translations).find(params[:post_id])
      @post.assign_attributes(post_params)
      @post.build_missing_translations
      set_target_translation

      if @translation && rewrite_selection
        render :create
      else
        redirect_to edit_admin_post_path(@post), alert: t("admin.posts.selection_rewrite.stale")
      end
    end

    private

      # The index has to match the one the form rendered, or the swapped-in
      # field would submit under the wrong nested attribute key.
      def set_target_translation
        translations = @post.post_translations.sort_by { |item| item.locale.to_s }
        @index = translations.index { |item| item.locale == selection_rewrite_params[:locale] }
        @translation = translations[@index] if @index
      end

      def rewrite_selection
        PostTranslations::Service.new(@translation).rewrite_selection(
          selection: selection_rewrite_params[:selection],
          selection_start: selection_rewrite_params[:selection_start].to_i,
          selection_end: selection_rewrite_params[:selection_end].to_i,
          instruction: selection_rewrite_params[:instruction]
        )
      end

      def post_params
        params.require(:post).permit(
          post_translations_attributes: [ :id, :locale, :title, :description, :content, :published, :published_at, :_destroy ]
        )
      end

      def selection_rewrite_params
        params.require(:selection_rewrite).permit(:locale, :selection, :selection_start, :selection_end, :instruction)
      end
  end
end
