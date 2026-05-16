class JotSpotController < PublicController
  def show
    @posts = Post.joins(:post_translations)
                 .where(post_translations: { locale: I18n.locale })
                 .where.not(published_at: nil)
                 .order(published_at: :desc)
                 .includes(:post_translations)
                 .distinct
  end
end