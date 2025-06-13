# frozen_string_literal: true

class UserProfilesController < ApplicationController
  include Authenticatable
  include Pundit::Authorization

  before_action :authorize_request
  before_action :set_user_profile
  before_action :authorize_user_profile

  def show
    authorize @user_profile
    render json: @user_profile
  end

  def update
    authorize @user_profile

    if @user_profile.update(user_profile_params)
      render json: @user_profile
    else
      render json: { errors: @user_profile.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_user_profile
    @user_profile = if params[:id]
      UserProfile.find(params[:id])
    else
      current_user.user_profile
    end
  end

  def authorize_user_profile
    authorize @user_profile
  end

  def user_profile_params
    params.require(:user_profile).permit(:bio, :avatar_url, :phone_number)
  end
end
