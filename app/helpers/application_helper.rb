module ApplicationHelper
  def locale_switch_path
    locale = I18n.locale == :es ? :en : :es
    translation = @post.post_translations.find { |item| item.locale == locale.to_s } if defined?(@post) && @post.is_a?(Post)

    return post_path(id: @post, locale: locale) if translation&.published?
    return posts_path(locale: locale) if defined?(@post) && @post.is_a?(Post)

    url_for(locale: locale)
  end

  def smart_date(date)
    return unless date

    ago = time_ago_in_words(date)
    days = (Date.current - date.to_date).to_i
    days < 2 ? ago : l(date.to_date, format: :long)
  end
end
