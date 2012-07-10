class ApplicationController < ActionController::Base
  protect_from_forgery
  force_ssl

  def admin?
    session[:username] == 'workingprogress' && session[:password] == 'simplepass1'
    return true
  end

end
