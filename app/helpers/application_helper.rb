module ApplicationHelper
  def smart_date(date)
    return unless date

    ago = time_ago_in_words(date)
    days = (Date.current - date.to_date).to_i
    days < 2 ? ago : l(date.to_date, format: :long)
  end
end
