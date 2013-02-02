class ApplicationController < ActionController::Base
  protect_from_forgery
  #force_ssl

  include SessionsHelper

  def admin?
    return SessionsHelper.valid_login?(session[:username], session[:password])
  end

end
