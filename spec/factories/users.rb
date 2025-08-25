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
      organization { nil }  # Global admins have no organization
      security_question { "What is your favorite animal?" }
      security_answer { "Roxy" }
    end

    trait :deactivated do
      active { false }
      deactivated_at { Time.current }
    end
  end
end
