module Mutations
  module Auth
    class Signup < Mutations::BaseMutation
      argument :organization_id, ID, required: true
      argument :email, String, required: true
      argument :password, String, required: true
      argument :role, String, required: true

      field :auth_payload, Types::AuthPayloadType, null: true
      field :errors, [String], null: false

      def resolve(organization_id:, email:, password:, role:)
        result = ::Auth::Signup.run(
          organization_id: organization_id,
          email: email,
          password: password,
          role: role
        )

        if result.valid?
          { auth_payload: result.result, errors: [] }
        else
          { auth_payload: nil, errors: result.errors.full_messages }
        end
      end
    end
  end
end
