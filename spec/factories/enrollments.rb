FactoryBot.define do
  factory :enrollment do
    association :user
    association :course

    status { Constants::EnrollmentStatus::STATUSES[:active] }
    grade { nil }

    trait :dropped do
      status { Constants::EnrollmentStatus::STATUSES[:dropped] }
    end

    trait :passed do
      status { Constants::EnrollmentStatus::STATUSES[:passed] }
      grade { "A" }
    end

    trait :failed do
      status { Constants::EnrollmentStatus::STATUSES[:failed] }
      grade { "F" }
    end
  end
end
