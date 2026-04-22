class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_locale

  def default_url_options
    { locale: I18n.locale }
  end

  private

  def set_locale
    locale = params[:locale] || I18n.default_locale
    locale = I18n.default_locale.to_s unless I18n.available_locales.include?(locale.to_sym)
    I18n.locale = locale
  end
end
