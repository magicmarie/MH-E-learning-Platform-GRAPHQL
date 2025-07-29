# frozen_string_literal: true

RSpec.describe EnrollmentPolicy do
  subject { described_class.new(current_user, enrollment) }

  let(:org)        { create(:organization) }
  let(:other_org)  { create(:organization) }
  let(:teacher)    { create(:user, :teacher, organization: org) }
  let(:student)    { create(:user,  organization: org) }
  let(:admin)      { create(:user, :org_admin, organization: org) }
  let(:global_admin) { create(:user, :global_admin) }
  let(:course)     { create(:course, user: teacher, organization: org) }
  let(:enrollment) { create(:enrollment, course: course, user: student) }

  shared_examples "allows access" do |action|
    it "permits #{action}" do
      expect(described_class.new(current_user, enrollment).public_send("#{action}?")).to eq(true)
    end
  end

  shared_examples "denies access" do |action|
    it "forbids #{action}" do
      expect(described_class.new(current_user, enrollment).public_send("#{action}?")).to eq(false)
    end
  end

  describe "permissions" do
    %i[index create update destroy].each do |action|
      context "#{action}?" do
        it_behaves_like "allows access", action do
          let(:current_user) { global_admin }
        end

        it_behaves_like "allows access", action do
          let(:current_user) { admin }
        end

        it_behaves_like "allows access", action do
          let(:current_user) { teacher }
        end

        it_behaves_like "denies access", action do
          let(:current_user) { student }
        end

        it_behaves_like "denies access", action do
          let(:current_user) { nil }
        end
      end
    end

    describe "#show?" do
      it_behaves_like "allows access", :show do
        let(:current_user) { global_admin }
      end

      it_behaves_like "allows access", :show do
        let(:current_user) { admin }
      end

      it_behaves_like "allows access", :show do
        let(:current_user) { teacher }
      end

      it_behaves_like "allows access", :show do
        let(:current_user) { student }
      end

      it_behaves_like "denies access", :show do
        let(:current_user) { create(:user, organization: org) }
      end

      it_behaves_like "denies access", :show do
        let(:current_user) { nil }
      end
    end
  end

  describe "Scope" do
    subject { described_class::Scope.new(current_user, Enrollment).resolve }

    let!(:course1) { create(:course, user: teacher, organization: org) }
    let!(:course2) { create(:course, user: create(:user, :teacher, organization: other_org), organization: other_org) }

    let!(:enrollment1) { create(:enrollment, course: course1, user: student) }
    let!(:enrollment2) { create(:enrollment, course: course2) }
    let!(:other_student) { create(:user, organization: org) }
    let!(:enrollment3) { create(:enrollment, course: course1, user: other_student) }

    context "as global admin" do
      let(:current_user) { global_admin }

      it "returns all enrollments" do
        expect(subject).to contain_exactly(enrollment1, enrollment2, enrollment3)
      end
    end

    context "as org admin" do
      let(:current_user) { admin }

      it "returns enrollments in their org's courses" do
        expect(subject).to contain_exactly(enrollment1, enrollment3)
      end
    end

    context "as teacher" do
      let(:current_user) { teacher }

      it "returns enrollments in their own courses" do
        expect(subject).to contain_exactly(enrollment1, enrollment3)
      end
    end

    context "as student" do
      let(:current_user) { student }

      it "returns only their own enrollments" do
        expect(subject).to contain_exactly(enrollment1)
      end
    end

    context "as nil user" do
      let(:current_user) { nil }

      it "returns nothing" do
        expect(subject).to be_empty
      end
    end
  end
end
