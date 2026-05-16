class JotSpotController < ApplicationController
  def show
    @posts = Post.order(published_at: :desc).where.not(published_at: nil)
  end
end
