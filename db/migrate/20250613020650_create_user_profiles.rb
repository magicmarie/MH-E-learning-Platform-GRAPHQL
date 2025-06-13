class CreateUserProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :user_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :first_name, default: ""
      t.string :last_name, default: ""
      t.string :org_member_id, default: nil, limit: 6
      t.text :bio, default: ""
      t.string :phone_number, default: ""

      t.timestamps
    end
  end
end
