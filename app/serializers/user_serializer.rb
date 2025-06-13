class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :role, :active, :organization_name,
              :deactivated_by_id, :activated_by_id

  def organization_name
    object.organization&.name
  end

  def role
    Constants::Roles::ROLE_NAMES[object.role]
  end
end
