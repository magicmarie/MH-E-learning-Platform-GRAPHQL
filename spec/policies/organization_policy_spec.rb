RSpec.describe OrganizationPolicy do
  subject { described_class.new(current_user, organization) }

  let(:organization) { build_stubbed(:organization) }

  describe "#create?" do
    context "when user is a global_admin" do
      let(:current_user) { build_stubbed(:user, :global_admin) }

      it "allows creating organization" do
        expect(subject.create?).to eq(true)
      end
    end

    context "when user is not a global_admin" do
      let(:current_user) { build_stubbed(:user, :org_admin) }

      it "forbids creating organization" do
        expect(subject.create?).to eq(false)
      end
    end
  end

  describe "#destroy?" do
    context "when user is a global_admin" do
      let(:current_user) { build_stubbed(:user, :global_admin) }

      it "allows destroying organization" do
        expect(subject.destroy?).to eq(true)
      end
    end

    context "when user is not a global_admin" do
      let(:current_user) { build_stubbed(:user, :teacher) }

      it "forbids destroying organization" do
        expect(subject.destroy?).to eq(false)
      end
    end
  end

  describe "#index_stats?" do
    context "when user is a global_admin" do
      let(:current_user) { build_stubbed(:user, :global_admin) }

      it "allows viewing stats" do
        expect(subject.index_stats?).to eq(true)
      end
    end

    context "when user is not a global_admin" do
      let(:current_user) { build_stubbed(:user, :org_admin) }

      it "forbids viewing stats" do
        expect(subject.index_stats?).to eq(false)
      end
    end
  end

  describe "#show?" do
    context "when user is a global_admin" do
      let(:current_user) { build_stubbed(:user, :global_admin) }

      it "allows viewing any organization" do
        expect(subject.show?).to eq(true)
      end
    end

    context "when user is an org_admin of the organization" do
      let(:current_user) { build_stubbed(:user, :org_admin, organization_id: organization.id) }

      it "allows viewing their own organization" do
        expect(subject.show?).to eq(true)
      end
    end

    context "when user is an org_admin of another organization" do
      let(:current_user) { build_stubbed(:user, :org_admin, organization_id: 999) }

      it "forbids viewing another organization" do
        expect(subject.show?).to eq(false)
      end
    end

    context "when user is a teacher" do
      let(:current_user) { build_stubbed(:user, :teacher, organization_id: organization.id) }

      it "forbids viewing organization" do
        expect(subject.show?).to eq(false)
      end
    end
  end

  describe "#update?" do
    context "same rules as show?" do
      let(:current_user) { build_stubbed(:user, :org_admin, organization_id: organization.id) }

      it "allows updating own organization" do
        expect(subject.update?).to eq(true)
      end
    end
  end

  describe "Scope" do
    subject { described_class::Scope.new(current_user, Organization).resolve }

    let!(:org1) { create(:organization) }
    let!(:org2) { create(:organization) }

    context "when user is a global_admin" do
      let(:current_user) { build_stubbed(:user, :global_admin) }

      it "returns all organizations" do
        expect(subject).to include(org1, org2)
      end
    end

    context "when user is an org_admin of org1" do
      let(:current_user) { build_stubbed(:user, :org_admin, organization_id: org1.id) }

      it "returns only their own organization" do
        expect(subject).to include(org1)
        expect(subject).not_to include(org2)
      end
    end

    context "when user is a student" do
      let(:current_user) { build_stubbed(:user, organization_id: org1.id) }

      it "returns no organizations" do
        expect(subject).to be_empty
      end
    end
  end
end
