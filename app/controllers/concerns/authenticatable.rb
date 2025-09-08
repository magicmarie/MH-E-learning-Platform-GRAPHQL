# frozen_string_literal: true

module Authenticatable
  def current_user
    return @current_user if defined?(@current_user)

    token = extract_token_from_context
    decoded = JsonWebToken.decode(token)
    raise GraphQL::ExecutionError, "Token expired or invalid" if decoded.nil?

    user = User.find_by(id: decoded[:user_id])
    raise GraphQL::ExecutionError, "Unauthorized or Account deactivated" if user.nil? || !user.active?

    @current_user = user
  end

  private

  def extract_token_from_context
    # Expect context[:headers] to be passed from GraphqlController
    auth_header = context[:headers]["Authorization"]
    auth_header&.split(" ")&.last
  end
end

