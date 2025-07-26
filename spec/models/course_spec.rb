require 'rails_helper'

RSpec.describe Course, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:organization) }
    it { should have_many(:enrollments) }
    it { should have_many(:users).through(:enrollments) }
    it { should have_many(:assignments).dependent(:destroy) }
    it { should have_many(:resources).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:course) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:course_code) }
    it { should validate_presence_of(:semester) }
    it { should validate_presence_of(:month) }
    it { should validate_presence_of(:year) }

    it {
      should validate_inclusion_of(:month)
        .in_range(1..12)
        .with_message("must be between 1 and 12")
    }

    context "year validation" do
      let(:course) { build(:course, year: 1800) }

      it "is invalid if year < 1900" do
        expect(course).not_to be_valid
        expect(course.errors[:year]).to include("must be a valid year")
      end
    end

    context "scoped uniqueness of month" do
      let(:org) { create(:organization) }
      let(:attrs) do
        {
          name: "Intro",
          course_code: "C123",
          semester: 1,
          year: 2025,
          month: 1,
          organization: org
        }
      end

      it "is invalid with duplicate details" do
        create(:course, **attrs)
        dup_course = build(:course, **attrs)
        expect(dup_course).not_to be_valid
        expect(dup_course.errors[:month]).to include("must be unique for the same course details in a given year and semester")
      end

      it "is valid when other attributes differ" do
        create(:course, **attrs)
        diff_course = build(:course, **attrs.merge(name: "Different"))
        expect(diff_course).to be_valid
      end
    end

    context "semester inclusion" do
      let(:course) { build(:course, semester: 99) }

      it "is invalid if semester is not in list" do
        expect(course).not_to be_valid
        expect(course.errors[:semester]).to include("is not included in the list")
      end
    end
  end

  describe "resources" do
    let(:course) { create(:course, :with_resources, resources_count: 2) }

    it "has the correct number of resources" do
      expect(course.resources.size).to eq(2)
    end
  end

  describe "#enrollment_count" do
    let(:course) { create(:course) }

    before { create_list(:enrollment, 3, course: course) }

    it "returns the correct count" do
      expect(course.enrollment_count).to eq(3)
    end
  end

  describe "#assignment_type_counts" do
    let(:course) { create(:course) }

    context "when no assignments exist" do
      it "returns zeroed counts" do
        expect(course.assignment_type_counts.values.all?(&:zero?)).to be true
      end
    end

    context "when assignments exist" do
      let(:type) { Constants::AssignmentTypes::ASSIGNMENT_TYPES[:homework] }

      before { create_list(:assignment, 2, course: course, assignment_type: type) }

      it "returns correct assignment counts" do
        expect(course.assignment_type_counts["homework"]).to eq(2)
      end
    end
  end

  describe "#semester_info" do
    let(:semester) { Constants::Semesters::SEMESTERS[:first] }
    let(:course) { build(:course, semester: semester) }

    it "returns human-readable semester name" do
      expect(course.semester_info).to eq(Constants::Semesters::SEMESTER_NAMES[semester])
    end
  end
end
