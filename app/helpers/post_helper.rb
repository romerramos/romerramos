module PostHelper
  def post_primary_translation(post)
    post.post_translation_for(I18n.default_locale)
  end
end
