# frozen_string_literal: true

class PasswordsController < ApplicationController
  skip_before_action :authorize_request
  before_action :validate_token
  before_action :validate_password_params

  def create
    user = User.find_by(email: params[:email])

    if user&.active?
      token = JsonWebToken.encode({ user_id: user.id }, 1.hour.from_now)
      reset_url = "http://localhost:5173/reset_password?token=#{token}"

      user.update!(reset_password_token_sent_at: Time.current)

      UserMailer.welcome_user(user, nil, reset_url).deliver_now

      render json: { message: "Password reset link sent to #{user.email}" }, status: :ok
    else
      render json: { error: "Email not found or inactive" }, status: :not_found
    end
  end

  def update
    user = User.find_by(id: @payload[:user_id])
    return render json: { error: "User not found" }, status: :not_found unless user

    # Prevent reuse: Check if token has already been used
    if user.reset_password_token_used_at.present? && user.reset_password_token_used_at > @payload[:iat].to_time
      return render json: { error: "This reset link has already been used" }, status: :unauthorized
    end

    if user.update(password_params.merge(reset_password_token_used_at: Time.current))
      render json: { message: "Password updated successfully" }, status: :ok
    else
      render json: { error: user.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.permit(:password, :password_confirmation)
  end

  def validate_token
    token = params[:token]
    return render json: { error: "Token is required" }, status: :bad_request if token.blank?

    begin
      @payload = JsonWebToken.decode(token)
      render json: { error: "Token expired" }, status: :unauthorized if @payload.blank?
    rescue JWT::ExpiredSignature
      render json: { error: "Token has expired" }, status: :unauthorized
    rescue JWT::DecodeError
      render json: { error: "Invalid token" }, status: :unauthorized
    end
  end

  def validate_password_params
    if params[:password].blank?
      render json: { error: "Password is required" }, status: :bad_request and return
    end

    if params[:password_confirmation].blank?
      render json: { error: "Password confirmation is required" }, status: :bad_request and return
    end

    if params[:password] != params[:password_confirmation]
      render json: { error: "Passwords do not match" }, status: :unprocessable_entity and return
    end
  end
end
