class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_registration_path, alert: "Try again later." }

  def new
    @user = User.new
  end

  def create
    @user = User.new(params.expect(user: %i[display_name email_address password password_confirmation]))
    if @user.save
      start_new_session_for @user
      redirect_to root_path, notice: "Welcome, #{@user.display_name}! Pick a category to start."
    else
      render :new, status: :unprocessable_entity
    end
  end
end
