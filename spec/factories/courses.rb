FactoryBot.define do
  factory :course do
    association :user
    association :organization

    name { "Intro to Testing" }
    course_code { "TEST101" }
    semester { Constants::Semesters::SEMESTERS[:first] }
    month { 1 }
    year { 2025 }

    trait :with_resources do
      transient do
        resources_count { 3 }
      end

      after(:create) do |course, evaluator|
        create_list(:resource, evaluator.resources_count, course: course)
      end
    end
  end
end
