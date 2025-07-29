# frozen_string_literal: true

RSpec.describe AssignmentPolicy do
  subject { described_class.new(current_user, assignment) }

  let(:org) { create(:organization) }
  let(:other_org) { create(:organization) }
  let(:course) { create(:course, organization: org) }
  let(:assignment) { create(:assignment, course: course) }

  describe "permissions" do
    %i[index? show? create? update? destroy?].each do |action|
      describe "#{action}" do
        context "as global_admin" do
          let(:current_user) { build_stubbed(:user, :global_admin) }

          it "permits access" do
            expect(subject.public_send(action)).to eq(true)
          end
        end

        context "as org_admin from same org" do
          let(:current_user) { build_stubbed(:user, :org_admin, organization: org) }

          it "permits access" do
            expect(subject.public_send(action)).to eq(true)
          end
        end

        context "as teacher from same org" do
          let(:current_user) { build_stubbed(:user, :teacher, organization: org) }

          it "permits access" do
            expect(subject.public_send(action)).to eq(true)
          end
        end

        context "as teacher from different org" do
          let(:current_user) { build_stubbed(:user, :teacher, organization: other_org) }

          it "forbids access" do
            expect(subject.public_send(action)).to eq(false)
          end
        end

        context "as org_admin from different org" do
          let(:current_user) { build_stubbed(:user, :org_admin, organization: other_org) }

          it "forbids access" do
            expect(subject.public_send(action)).to eq(false)
          end
        end
      end
    end

    describe "index? and show? for student" do
      let(:current_user) { build_stubbed(:user, organization: org) }

      context "when enrolled in the course" do
        before do
          allow(assignment.course).to receive_message_chain(:enrollments, :exists?)
            .with(user_id: current_user.id).and_return(true)
        end

        it "permits index" do
          expect(subject.index?).to eq(true)
        end

        it "permits show" do
          expect(subject.show?).to eq(true)
        end
      end

      context "when NOT enrolled in the course" do
        before do
          allow(assignment.course).to receive_message_chain(:enrollments, :exists?)
            .with(user_id: current_user.id).and_return(false)
        end

        it "forbids index" do
          expect(subject.index?).to eq(false)
        end

        it "forbids show" do
          expect(subject.show?).to eq(false)
        end
      end
    end

    describe "create?, update?, destroy? for student" do
      let(:current_user) { build_stubbed(:user, organization: org) }

      it "forbids create" do
        expect(subject.create?).to eq(false)
      end

      it "forbids update" do
        expect(subject.update?).to eq(false)
      end

      it "forbids destroy" do
        expect(subject.destroy?).to eq(false)
      end
    end

    describe "guest (nil user)" do
      let(:current_user) { nil }

      it "forbids all actions" do
        expect(subject.index?).to eq(false)
        expect(subject.show?).to eq(false)
        expect(subject.create?).to eq(false)
        expect(subject.update?).to eq(false)
        expect(subject.destroy?).to eq(false)
      end
    end
  end

  describe "Scope" do
    let!(:assignment_in_org) { create(:assignment, course: create(:course, organization: org)) }
    let!(:assignment_in_other_org) { create(:assignment, course: create(:course, organization: other_org)) }

    subject { described_class::Scope.new(current_user, Assignment).resolve }

    context "as global_admin" do
      let(:current_user) { build_stubbed(:user, :global_admin) }

      it "includes all assignments" do
        expect(subject).to include(assignment_in_org, assignment_in_other_org)
      end
    end

    context "as org_admin from org" do
      let(:current_user) { build_stubbed(:user, :org_admin, organization: org) }

      it "includes assignments from same org only" do
        expect(subject).to include(assignment_in_org)
        expect(subject).not_to include(assignment_in_other_org)
      end
    end

    context "as teacher from org" do
      let(:current_user) { build_stubbed(:user, :teacher, organization: org) }

      it "includes assignments from same org only" do
        expect(subject).to include(assignment_in_org)
        expect(subject).not_to include(assignment_in_other_org)
      end
    end

    context "as student enrolled in course" do
      let(:current_user) { create(:user, organization: org) }

      before do
        create(:enrollment, user: current_user, course: assignment_in_org.course)
      end

      it "includes enrolled assignments only" do
        expect(subject).to include(assignment_in_org)
        expect(subject).not_to include(assignment_in_other_org)
      end
    end

    context "as student NOT enrolled" do
      let(:current_user) { build_stubbed(:user, organization: org) }

      it "returns empty scope" do
        expect(subject).to be_empty
      end
    end

    context "as guest (nil user)" do
      let(:current_user) { nil }

      it "returns empty scope" do
        expect(subject).to be_empty
      end
    end
  end
end
