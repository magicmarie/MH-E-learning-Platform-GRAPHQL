module Auth
  class Signup < ActiveInteraction::Base
    string :email, :password
    integer :organization_id
    string :role, default: "student"

    def execute
      organization = Organization.find_by(id: organization_id)
      unless organization
        errors.add(:base, "Organization not found")
        return nil
      end

      role_integer = Constants::Roles::ROLES[role.to_sym]
      unless role_integer
        errors.add(:role, "Invalid role: #{role}")
        return nil
      end

      user = organization.users.new(email: email, password: password, role: role_integer)

      if user.save
        token = JsonWebToken.encode(user_id: user.id)
        {
          token: token,
          user: UserSerializer.new(user).as_json
        }
      else
        errors.merge!(user.errors)
        nil
      end
    end
  end
end
