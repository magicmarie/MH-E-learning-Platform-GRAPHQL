class Auth::ChangePassword < ActiveInteraction::Base
  object :user, class: User
  string :current_password
  string :new_password

  def execute
    unless user.authenticate(current_password)
      errors.add(:base, "Incorrect password")
      return nil
    end

    if user.update(password: new_password)
      { message: "Password updated successfully" }
    else
      errors.merge!(user.errors)
      nil
    end
  end
end
