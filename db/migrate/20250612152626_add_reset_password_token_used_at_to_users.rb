class AddResetPasswordTokenUsedAtToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :reset_password_token_used_at, :datetime
  end
end
