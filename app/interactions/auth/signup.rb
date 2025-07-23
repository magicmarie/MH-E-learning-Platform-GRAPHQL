module Auth
  class Signup < ActiveInteraction::Base
    string :email, :password
    integer :organization_id
    string :role, default: "student"

    def execute
      organization = Organization.find_by(id: organization_id)
      return errors.add(:base, "Organization not found") unless organization

      user = organization.users.new(email: email, password: password, role: role)

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
