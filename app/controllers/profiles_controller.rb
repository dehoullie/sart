class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if profile_params[:password].present?
      success = @user.update_with_password(profile_params)
    else
      filtered = profile_params.except(:password, :password_confirmation, :current_password)
      success = @user.update(filtered)
    end

    if success
      bypass_sign_in(@user) if profile_params[:password].present?
      redirect_to profile_path, notice: "Profile updated successfully"
    else
      render :edit
    end
  end

  private

  def profile_params
    params.require(:user).permit(
      :name,
      :country,
      :avatar,
      :remove_avatar,          # ← make sure this is here
      :current_password,
      :password,
      :password_confirmation
    )
  end
end
