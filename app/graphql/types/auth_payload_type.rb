module Types
  class AuthPayloadType < Types::BaseObject
    field :token, String, null: true
    field :user, Types::UserType, null: true
    field :message, String, null: true
    field :errors, [ String ], null: false
  end
end
