require "rails_helper"

RSpec.describe Assignment, type: :model do
  describe "associations" do
    it { should belong_to(:course) }
    it { should have_many(:assessments).dependent(:destroy) }
    it "can attach multiple files" do
      assignment = create(:assignment)
      expect(assignment.files).to be_attached
    end
  end

  describe "validations" do
    subject { build(:assignment) }

    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:deadline) }
    it { should validate_presence_of(:assignment_type) }

    it { should validate_inclusion_of(:assignment_type).in_array(Constants::AssignmentTypes::ASSIGNMENT_TYPES.values) }

    it "allows nil max_score" do
      assignment = build(:assignment, max_score: nil)
      expect(assignment).to be_valid
    end

    it "rejects negative max_score" do
      assignment = build(:assignment, max_score: -10)
      expect(assignment).not_to be_valid
      expect(assignment.errors[:max_score]).to include("must be greater than or equal to 0")
    end
  end

  describe "#assignment_type_name" do
    it "returns human-readable name" do
      assignment = build(:assignment, assignment_type: Constants::AssignmentTypes::ASSIGNMENT_TYPES[:quiz])
      expect(assignment.assignment_type_name).to eq(:quiz)
    end
  end

  describe "#assessment_count, #submissions_count, #assessed_count" do
    let(:assignment) { create(:assignment) }

    before do
      create_list(:assessment, 2, assignment: assignment, submitted_at: Time.current)
      create(:assessment, assignment: assignment, submitted_at: nil)
      create(:assessment, assignment: assignment, assessed_on: Time.current)
    end

    it "returns correct counts" do
      expect(assignment.assessment_count).to eq(4)
      expect(assignment.submissions_count).to eq(2)
      expect(assignment.assessed_count).to eq(1)
    end
  end
end
