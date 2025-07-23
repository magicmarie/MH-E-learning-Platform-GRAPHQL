class Auth::VerifySecurity < ActiveInteraction::Base
  string :email
  string :security_answer

  def execute
    user = User.find_by(email: email)

    unless user&.global_admin?
      errors.add(:base, "Unauthorized")
      return nil
    end

    unless user.active?
      errors.add(:base, "Account is deactivated")
      return nil
    end

    unless user.correct_security_answer?(security_answer)
      errors.add(:base, "Incorrect security answer")
      return nil
    end

    token = JsonWebToken.encode(user_id: user.id)
    { token: token, user: UserSerializer.new(user).as_json }
  end
end
