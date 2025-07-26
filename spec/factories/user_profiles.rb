FactoryBot.define do
  factory :user_profile do
    association :user

    sequence(:org_member_id) { |n| "ID#{n.to_s.rjust(3, '0')}" } # e.g., ID001, ID002

    trait :with_avatar do
      after(:build) do |profile|
        profile.avatar.attach(
          io: File.open(Rails.root.join('spec/fixtures/files/avatar.png')),
          filename: 'avatar.png',
          content_type: 'image/png'
        )
      end
    end
  end
end
