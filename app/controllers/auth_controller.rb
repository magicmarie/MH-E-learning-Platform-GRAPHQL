# frozen_string_literal: true

class AuthController < ApplicationController
  include Authenticatable

  before_action :authorize_request, only: [ :change_password ]

  def signup
    result = Auth::Signup.run(organization_id: params[:organization_id], email: params[:email],
                              password: params[:password], role: params[:role])
    if result.valid?
      render json: result.result, status: :created
    else
      render json: { errors: result.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    result = Auth::Login.run(
      email: params[:email],
      password: params[:password],
      organization_id: params[:organization_id],
      security_answer: params[:security_answer]
    )

    status = result.result[:status] || :unprocessable_entity

    if result.valid? || result.result[:status] == :partial_content
      render json: result.result.except(:status), status: status
    else
      render json: { errors: result.errors.full_messages }, status: status
    end
  end

  def verify_security
    result = Auth::VerifySecurity.run(email: params[:email],
                                      security_answer: params[:security_answer])
    if result.valid?
      render json: result.result, status: :ok
    else
      render json: { error: result.errors.full_messages.join(", ") }, status: :unauthorized
    end
  end

  def change_password
    result = Auth::ChangePassword.run(user: current_user,
                                      current_password: params[:current_password],
                                      new_password: params[:new_password])
    if result.valid?
      render json: result.result, status: :ok
    else
      render json: { errors: result.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
