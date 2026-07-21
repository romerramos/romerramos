class PostsController < PublicController
  def index
    @pagy, @posts = pagy(:offset, Post.publicly_visible_in(I18n.locale), limit: 10)
  end

  def show
    @post = Post.publicly_visible_in(I18n.locale).find(params[:id])
  end
end
