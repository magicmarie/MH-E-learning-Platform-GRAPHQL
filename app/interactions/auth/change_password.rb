class Auth::ChangePassword < ActiveInteraction::Base
  object :user, class: User
  string :current_password
  string :new_password

  def execute
    return add_error("Incorrect password") unless user.authenticate(current_password)
    return add_error("Password can't be blank") if new_password.blank?

    if user.update(password: new_password)
      { message: "Password updated successfully" }
    else
      errors.merge!(user.errors)
      nil
    end
  end

  private

  def add_error(message)
    errors.add(:base, message)
    nil
  end
end
