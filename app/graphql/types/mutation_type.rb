# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :signup, mutation: Mutations::Auth::Signup
    field :login, mutation: Mutations::Auth::Login
    field :verify_security, mutation: Mutations::Auth::VerifySecurity
    field :change_password, mutation: Mutations::Auth::ChangePassword
    # field :create_user, mutation: Mutations::Users::CreateUser
  end
end
