FactoryBot.define do
  factory :assessment do
    association :enrollment
    association :assignment
    score { rand(0..100) }
    submitted_at { nil }
    assessed_on { nil }

    after(:build) do |assessment|
      file_path = Rails.root.join("spec/fixtures/files/sample.pdf")
      if File.exist?(file_path)
        assessment.files.attach(
          io: File.open(file_path),
          filename: "sample.pdf",
          content_type: "application/pdf"
        )
      end
    end
  end
end
