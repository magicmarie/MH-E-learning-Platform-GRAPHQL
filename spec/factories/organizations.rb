FactoryBot.define do
  factory :organization do
    name { Faker::Company.unique.name }
    organization_code { SecureRandom.alphanumeric(6).upcase }
  end
end
