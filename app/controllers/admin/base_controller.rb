module Admin
  class BaseController < ApplicationController
    layout "admin"
    # Authentication concern already requires authentication by default
    # Admin controllers inherit this behavior without skipping it
  end
end
