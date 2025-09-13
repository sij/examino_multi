class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:name, :password))
      # Valorizza i campi login_ip e login_at
      user.update!(
        login_ip: request.remote_ip,
        login_at: Time.current
      )
      session[:user_id] = user.id
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Try another username or password."
    end
  end

  def destroy
    terminate_session
    session[:user_id] = nil
    redirect_to new_session_path
  end
end