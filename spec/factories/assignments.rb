FactoryBot.define do
  factory :assignment do
    association :course

    sequence(:title) { |n| "Assignment #{n}" }
    deadline { 1.week.from_now }
    max_score { 100 }

    assignment_type { Constants::AssignmentTypes::ASSIGNMENT_TYPES[:project] }

    after(:build) do |assignment|
      file_path = Rails.root.join("spec/fixtures/files/sample.pdf")
      if File.exist?(file_path)
        assignment.files.attach(
          io: File.open(file_path),
          filename: "sample.pdf",
          content_type: "application/pdf"
        )
      end
    end
  end
end
