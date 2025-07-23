# frozen_string_literal: true

module Auth
  class Login < ActiveInteraction::Base
    string :email, :password
    integer :organization_id, default: nil
    string :security_answer, default: nil

    def execute
      user = find_user
      return error("Invalid credentials", :unauthorized) unless user&.authenticate(password)
      return error("Account is deactivated", :unauthorized) unless user.active?

      if user.global_admin?
        return mfa_prompt if security_answer.blank?
        return error("Incorrect security answer", :unauthorized) unless user.correct_security_answer?(security_answer)
      end

      token = JsonWebToken.encode(user_id: user.id)
      success(token:, user:)
    end

    private

    def find_user
      if organization_id.present?
        User.find_by(email: email, organization_id: organization_id)
      else
        User.find_by(email: email)
      end
    end

    def error(message, status)
      errors.add(:base, message)
      {
        status: status,
        error: message
      }
    end

    def mfa_prompt
      {
        status: :partial_content,
        message: "MFA required"
      }
    end

    def success(token:, user:)
      {
        status: :ok,
        token: token,
        user: ActiveModelSerializers::SerializableResource.new(user)
      }
    end
  end
end
