class AddActivatedByIdToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :activated_by_id, :integer
  end
end
