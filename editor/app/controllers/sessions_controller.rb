class SessionsController < ApplicationController
  def new
  end

  def create
    reset_session
    session[:password] = params[:password]
    if admin?
      redirect_to edits_path
    else
      redirect_to login_path
    end
  end
  
  def destroy
    reset_session
    flash[:notice] = 'Successfully logged out'
    redirect_to login_path
  end
end
