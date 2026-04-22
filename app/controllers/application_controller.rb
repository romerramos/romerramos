class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_locale

  private

  def request_authentication
    session[:return_to_after_authenticating] = request.url
    redirect_to login_path
  end

  def set_locale
    locale = params[:locale] || I18n.default_locale
    locale = I18n.default_locale.to_s unless I18n.available_locales.include?(locale.to_sym)
    I18n.locale = locale
  end

  def default_url_options
    if I18n.locale == I18n.default_locale
      {}
    else
      { locale: I18n.locale }
    end
  end
end
