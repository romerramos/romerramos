class PublicController < ApplicationController
  allow_unauthenticated_access

  def default_url_options
    { locale: I18n.locale }
  end
end
