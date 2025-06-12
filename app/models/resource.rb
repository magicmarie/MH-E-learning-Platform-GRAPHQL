class Resource < ApplicationRecord
  belongs_to :course

  has_one_attached :file, dependent: :destroy
end
