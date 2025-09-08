# frozen_string_literal: true

# frozen_string_literal: true

module Types
  class UserType < Types::BaseObject
    field :id, ID, null: false
    field :email, String, null: false
    field :role, String, null: false
    field :active, Boolean, null: false
    field :organization_name, String, null: true
    field :deactivated_by_id, ID, null: true
    field :activated_by_id, ID, null: true

    def role
      Constants::Roles::ROLE_NAMES[object.role]
    end

    def organization_name
      object.organization&.name
    end
  end
end

