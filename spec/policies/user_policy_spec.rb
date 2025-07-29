RSpec.describe UserPolicy do
  subject { described_class.new(current_user, target_user) }

  let(:org) { create(:organization) }
  let(:other_org) { create(:organization) }
  let(:target_user) { create(:user, organization: org) }

  context "index?" do
    context "for org_admin" do
      let(:current_user) { build_stubbed(:user, :org_admin) }

      it "permits access" do
        expect(subject.index?).to eq(true)
      end
    end

    context "for global_admin" do
      let(:current_user) { build_stubbed(:user, :global_admin) }

      it "permits access" do
        expect(subject.index?).to eq(true)
      end
    end

    context "for teacher" do
      let(:current_user) { build_stubbed(:user, :teacher) }

      it "permits access" do
        expect(subject.index?).to eq(true)
      end
    end

    context "for student" do
      let(:current_user) { build_stubbed(:user) }

      it "forbids access" do
        expect(subject.index?).to eq(false)
      end
    end
  end

  context "create?" do
    context "as global_admin" do
      let(:current_user) { build_stubbed(:user, :global_admin) }

      context "when creating org_admin" do
        let(:target_user) { build_stubbed(:user, :org_admin) }

        it "allows creating org admin" do
        expect(subject.create?).to eq(true)
      end
      end

      context "when creating teacher" do
       let(:target_user) { build_stubbed(:user, :teacher) }

        it "allows creating teacher" do
          expect(subject.create?).to eq(true)
        end
      end

      it "allows creating student" do
        expect(subject.create?).to eq(true)
      end
    end

    context "as org_admin" do
      let(:current_user) { build_stubbed(:user, :org_admin) }

      context "when creating teacher" do
        let(:target_user) { build_stubbed(:user, :teacher) }

        it "allows creating teacher" do
          expect(subject.create?).to eq(true)
        end
      end

      context "when creating another org_admin" do
        let(:target_user) { build_stubbed(:user, :teacher) }

        it "forbids creating org admin" do
          expect(subject.create?).to eq(true)
        end
      end

      context "when creating student" do
        let(:target_user) { build_stubbed(:user, :teacher) }

        it "allows creating student" do
          expect(subject.create?).to eq(true)
        end
      end
    end
  end

  shared_examples "activate/deactivate/update/destroy" do |action|
    subject { described_class.new(current_user, target_user) }

    let(:org) { build_stubbed(:organization) }
    let(:other_org) { build_stubbed(:organization) }
    let(:target_user) { build_stubbed(:user, organization: org) }


    context "user not active" do
      let(:current_user) { build_stubbed(:user, :org_admin, organization: org, active: false) }

      it "forbids #{action} when user is inactive" do
        expect(subject.public_send("#{action}?")).to eq(false)
      end
    end

    context "global_admin" do
      let(:current_user) { build_stubbed(:user, :global_admin, active: true) }

      it "allows #{action} on student" do
        expect(subject.public_send("#{action}?")).to eq(true)
      end

      context "target is org_admin" do
        let(:target_user) { build_stubbed(:user, :org_admin) }

        it "allows #{action} on org_admin" do
          expect(subject.public_send("#{action}?")).to eq(true)
        end
      end
    end

    context "org_admin from same organization" do
      let(:current_user) { build_stubbed(:user, :org_admin, organization: org, active: true) }

      it "allows #{action} on student in same org" do
        expect(subject.public_send("#{action}?")).to eq(true)
      end

      context "target is teacher" do
        let(:target_user) { build_stubbed(:user, :teacher, organization: org) }

        it "allows #{action} on teacher in same org" do
          expect(subject.public_send("#{action}?")).to eq(true)
        end
      end

      context "target is org_admin" do
        let(:target_user) { build_stubbed(:user, :org_admin, organization: org) }

        it "forbids #{action} on another org_admin in same org" do
          expect(subject.public_send("#{action}?")).to eq(false)
        end
      end

      context "target is global_admin" do
        let(:target_user) { build_stubbed(:user, :global_admin) }

        it "forbids #{action} on global_admin" do
          expect(subject.public_send("#{action}?")).to eq(false)
        end
      end
    end

    context "org_admin from different organization" do
      let(:current_user) { build_stubbed(:user, :org_admin, organization: other_org, active: true) }
      let(:target_user) { build_stubbed(:user, organization: org) }

      it "forbids #{action} on user in different org" do
        expect(subject.public_send("#{action}?")).to eq(false)
      end
    end

    context "teacher" do
      let(:current_user) { build_stubbed(:user, :teacher, active: true) }

      it "forbids #{action} by teacher" do
        expect(subject.public_send("#{action}?")).to eq(false)
      end
    end

    context "student" do
      let(:current_user) { build_stubbed(:user, active: true) }

      it "forbids #{action} by student" do
        expect(subject.public_send("#{action}?")).to eq(false)
      end
    end
  end

  %i[activate deactivate update destroy].each do |action|
    describe "##{action}?" do
      it_behaves_like "activate/deactivate/update/destroy", action
    end
  end

  describe "bulk_create?" do
    subject { described_class.new(current_user, nil) }

    context "when user is a global_admin" do
      let(:current_user) { build_stubbed(:user, :global_admin) }

      it "allows bulk creation" do
        expect(subject.bulk_create?).to eq(true)
      end
    end

    context "when user is an org_admin" do
      let(:current_user) { build_stubbed(:user, :org_admin) }

      it "allows bulk creation" do
        expect(subject.bulk_create?).to eq(true)
      end
    end

    context "when user is a student (default role)" do
      let(:current_user) { build_stubbed(:user) }

      it "forbids bulk creation" do
        expect(subject.bulk_create?).to eq(false)
      end
    end
  end

  describe "show?" do
    subject { described_class.new(current_user, build_stubbed(:user)) }

    context "when user is an org_admin" do
      let(:current_user) { build_stubbed(:user, :org_admin) }

      it "allows viewing the user" do
        expect(subject.show?).to eq(true)
      end
    end

    context "when user is a global_admin" do
      let(:current_user) { build_stubbed(:user, :global_admin) }

      it "allows viewing the user" do
        expect(subject.show?).to eq(true)
      end
    end

    context "when user is a teacher" do
      let(:current_user) { build_stubbed(:user, :teacher) }

      it "allows viewing the user" do
        expect(subject.show?).to eq(true)
      end
    end

    context "when user is a student" do
      let(:current_user) { build_stubbed(:user) }

      it "allows viewing the user" do
        expect(subject.show?).to eq(true)
      end
    end

    context "when user is nil (guest)" do
      let(:current_user) { nil }

      it "forbids viewing the user" do
        expect(subject.show?).to eq(false)
      end
    end
  end

  describe "Scope" do
    subject { described_class::Scope.new(current_user, User.all).resolve }

    context "global_admin" do
      let(:current_user) { build_stubbed(:user, :global_admin) }
      it "returns all users" do
        expect(subject).to eq(User.all)
      end
    end

    context "org_admin" do
      let(:current_user) { create(:user, :org_admin, organization: org) }
      let!(:user_in_org) { create(:user, organization: org) }
      let!(:user_in_other_org) { create(:user, organization: other_org) }

      it "returns users only in the same org" do
        expect(subject).to include(user_in_org)
        expect(subject).not_to include(user_in_other_org)
      end
    end

    context "teacher" do
      let(:current_user) { create(:user, :teacher, organization: org) }
      let!(:student_in_org) { create(:user, organization: org) }
      let!(:teacher_in_org) { create(:user, :teacher, organization: org) }

      it "returns only students in the same org" do
        expect(subject).to include(student_in_org)
        expect(subject).not_to include(teacher_in_org)
      end
    end

    context "student or guest" do
      let(:current_user) { create(:user, organization: org) }
      it { is_expected.to be_empty }
    end
  end
end
