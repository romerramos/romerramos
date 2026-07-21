class PostsController < PublicController
  def index
    @pagy, @posts = pagy(:offset, Post.publicly_visible_in(I18n.locale).recent_first, limit: 10)
  end

  def show
    @post = Post.publicly_visible_in(I18n.locale).find(params[:id])
    @translation = @post.translation_for(I18n.locale)
  end
end
