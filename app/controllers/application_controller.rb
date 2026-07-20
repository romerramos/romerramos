class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  around_action :switch_locale

  private

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to login_path
    end

    def switch_locale(&action)
      locale = params[:locale].presence_in(I18n.available_locales.map(&:to_s)) || I18n.default_locale
      I18n.with_locale(locale, &action)
    end

    def default_url_options
      I18n.locale == I18n.default_locale ? {} : { locale: I18n.locale }
    end
end
