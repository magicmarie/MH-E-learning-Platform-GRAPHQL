FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { "securepass123" }
    role { Constants::Roles::ROLES[:student] }
    organization

    trait :teacher do
      role { Constants::Roles::ROLES[:teacher] }
    end

    trait :org_admin do
      role { Constants::Roles::ROLES[:org_admin] }
    end

    trait :global_admin do
      role { Constants::Roles::ROLES[:global_admin] }
      security_question { "What is your favorite animal?" }
      security_answer { "Roxy" }
    end

    trait :deactivated do
      active { false }
      deactivated_at { Time.current }
    end

    after(:create) do |user|
      create(:user_profile, user: user) unless user.global_admin?
    end
  end
end
