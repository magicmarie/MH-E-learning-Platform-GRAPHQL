class UserProfileSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name, :bio, :avatar_url, :phone_number, :user_id

  def avatar_url
    Rails.application.routes.url_helpers.url_for(object.avatar) if object.avatar.attached?
  end
end
