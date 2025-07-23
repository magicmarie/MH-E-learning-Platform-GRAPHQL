# frozen_string_literal: true

module Users
  class BulkCreateUsers < ActiveInteraction::Base
    object :current_user, class: User
    file :file
    symbol :incoming_role

    def execute
      role_int = Constants::Roles::ROLES[incoming_role]

      if disallowed_admin_creation?(role_int)
        errors.add(:base, "Org admins cannot create '#{incoming_role}' users")
        return nil
      end

      unless allowed_roles.include?(role_int)
        errors.add(:base, "Role '#{incoming_role}' not allowed")
        return nil
      end

      users_data = parse_csv(file)
      return nil if users_data.nil?

      created_users = []
      failed_users = []

      users_data.each do |data|
        result = Users::CreateUser.run(
          current_user: current_user,
          email: data[:email],
          incoming_role: incoming_role
        )

        if result.valid?
          created_users << result.result
        else
          failed_users << { email: data[:email], errors: result.errors.full_messages }
        end
      end

      { created: created_users, failed: failed_users }
    end

    private

    def allowed_roles
      [
        Constants::Roles::ROLES[:teacher],
        Constants::Roles::ROLES[:student]
      ]
    end

    def disallowed_admin_creation?(role_int)
      role_int == Constants::Roles::ROLES[:global_admin] || role_int == Constants::Roles::ROLES[:org_admin]
    end

    def parse_csv(file)
      csv = CSV.parse(file.read, headers: true)
      csv.map { |row| row.to_hash.symbolize_keys.slice(:email) }
    rescue => e
      errors.add(:base, "Failed to parse CSV: #{e.message}")
      nil
    end
  end
end
