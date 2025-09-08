module Mutations
  module Auth
    class ChangePassword < Mutations::BaseMutation
      include Authenticatable

      argument :current_password, String, required: true
      argument :new_password, String, required: true

      field :success, Boolean, null: false
      field :errors, [String], null: false

      def resolve(current_password:, new_password:)
        result = ::Auth::ChangePassword.run(
          user: current_user,
          current_password: current_password,
          new_password: new_password
        )

        if result.valid?
          { success: true, errors: [] }
        else
          { success: false, errors: result.errors.full_messages }
        end
      end
    end
  end
end
