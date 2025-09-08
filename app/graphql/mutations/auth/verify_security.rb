module Mutations
  module Auth
    class VerifySecurity < Mutations::BaseMutation
      argument :email, String, required: true
      argument :security_answer, String, required: true

      field :verified, Boolean, null: false
      field :errors, [String], null: false

      def resolve(email:, security_answer:)
        result = ::Auth::VerifySecurity.run(email: email, security_answer: security_answer)

        if result.valid?
          { verified: result.result[:verified], errors: [] }
        else
          { verified: false, errors: result.errors.full_messages }
        end
      end
    end
  end
end
