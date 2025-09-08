# module Mutations
#   module Users
#     class CreateUser < Mutations::BaseMutation
#       include GraphqlAuthenticatable
#       include UserManagement

#       # Inputs
#       argument :email, String, required: true
#       argument :role, String, required: true

#       # Outputs
#       field :user, Types::UserType, null: true
#       field :errors, [String], null: false

#       def resolve(email:, role:)
#         # Initialize the new user for authorization
#         new_user = current_user.organization.users.new(email: email)

#         # Pundit authorization
#         authorize new_user, :create?

#         # Call ActiveInteraction
#         result = ::Users::CreateUser.run(
#           current_user: current_user,
#           email: email,
#           incoming_role: role.to_sym
#         )

#         if result.valid?
#           { user: result.result, errors: [] }
#         else
#           { user: nil, errors: result.errors.full_messages }
#         end
#       rescue Pundit::NotAuthorizedError
#         { user: nil, errors: ["Not authorized to create user"] }
#       end
#     end
#   end
# end
