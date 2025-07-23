# frozen_string_literal: true

module Admin
  module Users
    class CreateUser < ActiveInteraction::Base
      object :current_user, class: User
      string :email
      symbol :incoming_role
      integer :organization_id

      validates :incoming_role, inclusion: { in: Constants::Roles::ROLES.keys }

      def execute
        role_int = Constants::Roles::ROLES[incoming_role]

        if role_int == Constants::Roles::ROLES[:global_admin]
          errors.add(:base, "Cannot create global_admin")
          return nil
        end

        unless allowed_roles.include?(role_int)
          errors.add(:base, "Role '#{incoming_role}' not allowed")
          return nil
        end

        organization = Organization.find_by(id: organization_id)
        unless organization
          errors.add(:base, "Organization not found")
          return nil
        end

        temp_password = SecureRandom.alphanumeric(8)

        user = organization.users.new(
          email: email,
          role: role_int,
          password: temp_password,
          password_confirmation: temp_password
        )

        if user.save
          send_welcome_email(user, temp_password)
          user
        else
          errors.merge!(user.errors)
          nil
        end
      end

      private

      def allowed_roles
        [
          Constants::Roles::ROLES[:org_admin],
          Constants::Roles::ROLES[:teacher],
          Constants::Roles::ROLES[:student]
        ]
      end

      def send_welcome_email(user, temp_password)
        token = JsonWebToken.encode({ user_id: user.id }, 15.minutes.from_now)
        reset_url = "#{Rails.application.routes.url_helpers.root_url}reset_password?token=#{token}"

        UserMailer.welcome_user(user, temp_password, reset_url).deliver_now
      rescue => e
        Rails.logger.error("Failed to send welcome email to #{user.email}: #{e.message}")
      end
    end
  end
end
