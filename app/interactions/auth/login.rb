# frozen_string_literal: true

module Auth
  class Login < ActiveInteraction::Base
    string :email, :password
    integer :organization_id, default: nil
    string :security_answer, default: nil

    validate :organization_id_required_unless_global_admin

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
        User.global_admins.find_by(email: email)
      end
    end

    def organization_id_required_unless_global_admin
      return if organization_id.present?

      # Check if this email belongs to THE global admin
      unless User.global_admins.exists?(email: email)
        errors.add(:organization_id, "is required")
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
