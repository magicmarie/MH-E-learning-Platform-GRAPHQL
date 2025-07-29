class UserProfile < ApplicationRecord
  has_one_attached :avatar
  belongs_to :user

  validates :user_id, uniqueness: true

  validates :org_member_id,
    uniqueness: true,
    length: { maximum: 6 },
    allow_nil: true
end
