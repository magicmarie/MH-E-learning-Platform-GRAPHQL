module Mutations
  module Auth
    class Login < Mutations::BaseMutation
      argument :email, String, required: true
      argument :password, String, required: true
      argument :organization_id, ID, required: false
      argument :security_answer, String, required: false

      field :auth_payload, Types::AuthPayloadType, null: true

      def resolve(email:, password:, organization_id: nil, security_answer: nil)
        result = ::Auth::Login.run(
          email: email,
          password: password,
          organization_id: organization_id,
          security_answer: security_answer
        )

        if result.valid?
          payload = result.result

          if payload[:message] == "MFA required"
            { auth_payload: { message: "MFA required", errors: [] } }
          else
            { auth_payload: { token: payload[:token], user: payload[:user], message: nil, errors: [] } }
          end
        else
          { auth_payload: { errors: result.errors.full_messages || [] } }
        end
      end
    end
  end
end
