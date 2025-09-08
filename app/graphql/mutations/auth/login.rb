module Mutations
  module Auth
    class Login < Mutations::BaseMutation
      argument :email, String, required: true
      argument :password, String, required: true
      argument :organization_id, ID, required: true
      argument :security_answer, String, required: false

      field :token, String, null: true
      field :user, Types::UserType, null: true
      field :errors, [String], null: false

      def resolve(email:, password:, organization_id:, security_answer: nil)
        result = ::Auth::Login.run(
          email: email,
          password: password,
          organization_id: organization_id,
          security_answer: security_answer
        )

        # status = result.result[:status] || :unprocessable_entity

        if result.valid? || result.result[:status] == :partial_content
          { user: result.result[:user], token: result.result[:token], errors: [] }
        else
          { user: nil, token: nil, errors: result.errors.full_messages }
        end
      end
    end
  end
end
