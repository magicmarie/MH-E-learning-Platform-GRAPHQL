FactoryBot.define do
  factory :resource do
    association :course

    after(:build) do |resource|
      file_path = Rails.root.join("spec/fixtures/files/sample.pdf")
      if File.exist?(file_path)
        resource.file.attach(
          io: File.open(file_path),
          filename: "sample.pdf",
          content_type: "application/pdf"
        )
      end
    end
  end
end
