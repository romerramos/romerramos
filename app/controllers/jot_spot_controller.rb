class JotSpotController < PublicController
  def show
    @posts = Post.published
                 .recent_first
                 .joins(:post_translations)
                 .where(post_translations: { locale: I18n.locale })
                 .includes(:post_translations)
                 .distinct
  end
end
