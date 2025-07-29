# frozen_string_literal: true

RSpec.describe ResourcePolicy do
  subject { described_class.new(current_user, resource) }

  let(:org) { create(:organization) }
  let(:other_org) { create(:organization) }
  let(:course) { create(:course, organization: org) }
  let(:resource) { create(:resource, course: course) }

  describe "index?" do
    context "as global_admin" do
      let(:current_user) { build_stubbed(:user, :global_admin) }

      it "permits access" do
        expect(subject.index?).to eq(true)
      end
    end

    context "as org_admin from same org" do
      let(:current_user) { build_stubbed(:user, :org_admin, organization: org) }

      it "permits access" do
        expect(subject.index?).to eq(true)
      end
    end

    context "as teacher from same org" do
      let(:current_user) { build_stubbed(:user, :teacher, organization: org) }

      it "permits access" do
        expect(subject.index?).to eq(true)
      end
    end

    context "as student enrolled in the course" do
      let(:current_user) { build_stubbed(:user, organization: org) }

      before do
        allow(resource.course).to receive_message_chain(:enrollments, :exists?).with(user_id: current_user.id).and_return(true)
      end

      it "permits access" do
        expect(subject.index?).to eq(true)
      end
    end

    context "as student NOT enrolled in the course" do
      let(:current_user) { build_stubbed(:user, organization: org) }

      before do
        allow(resource.course).to receive_message_chain(:enrollments, :exists?).with(user_id: current_user.id).and_return(false)
      end

      it "forbids access" do
        expect(subject.index?).to eq(false)
      end
    end

    context "as org_admin from different org" do
      let(:current_user) { build_stubbed(:user, :org_admin, organization: other_org) }

      it "forbids access" do
        expect(subject.index?).to eq(false)
      end
    end

    context "as teacher from different org" do
      let(:current_user) { build_stubbed(:user, :teacher, organization: other_org) }

      it "forbids access" do
        expect(subject.index?).to eq(false)
      end
    end

    context "as student from different org" do
      let(:current_user) { build_stubbed(:user, organization: other_org) }

      it "forbids access" do
        expect(subject.index?).to eq(false)
      end
    end

    context "as guest (nil user)" do
      let(:current_user) { nil }

      it "forbids access" do
        expect(subject.index?).to eq(false)
      end
    end
  end

  describe "show?" do
    context "as global_admin" do
      let(:current_user) { build_stubbed(:user, :global_admin) }

      it "permits access" do
        expect(subject.show?).to eq(true)
      end
    end

    context "as org_admin from same org" do
      let(:current_user) { build_stubbed(:user, :org_admin, organization: org) }

      it "permits access" do
        expect(subject.show?).to eq(true)
      end
    end

    context "as teacher from same org" do
      let(:current_user) { build_stubbed(:user, :teacher, organization: org) }

      it "permits access" do
        expect(subject.show?).to eq(true)
      end
    end

    context "as student enrolled in the course" do
      let(:current_user) { build_stubbed(:user, organization: org) }

      before do
        allow(resource.course).to receive_message_chain(:enrollments, :exists?).with(user_id: current_user.id).and_return(true)
      end

      it "permits access" do
        expect(subject.show?).to eq(true)
      end
    end

    context "as student NOT enrolled in the course" do
      let(:current_user) { build_stubbed(:user, organization: org) }

      before do
        allow(resource.course).to receive_message_chain(:enrollments, :exists?).with(user_id: current_user.id).and_return(false)
      end

      it "forbids access" do
        expect(subject.show?).to eq(false)
      end
    end

    context "as student from different org" do
      let(:current_user) { build_stubbed(:user, organization: other_org) }

      it "forbids access" do
        expect(subject.show?).to eq(false)
      end
    end

    context "as guest (nil user)" do
      let(:current_user) { nil }

      it "forbids access" do
        expect(subject.show?).to eq(false)
      end
    end
  end

  shared_examples "create/update/destroy for resource" do |action|
    subject { described_class.new(current_user, resource) }

    context "as global_admin" do
      let(:current_user) { build_stubbed(:user, :global_admin) }

      it "permits #{action}" do
        expect(subject.public_send("#{action}?")).to eq(true)
      end
    end

    context "as org_admin from same org" do
      let(:current_user) { build_stubbed(:user, :org_admin, organization: org) }

      it "permits #{action}" do
        expect(subject.public_send("#{action}?")).to eq(true)
      end
    end

    context "as teacher from same org" do
      let(:current_user) { build_stubbed(:user, :teacher, organization: org) }

      it "permits #{action}" do
        expect(subject.public_send("#{action}?")).to eq(true)
      end
    end

    context "as org_admin from different org" do
      let(:current_user) { build_stubbed(:user, :org_admin, organization: other_org) }

      it "forbids #{action}" do
        expect(subject.public_send("#{action}?")).to eq(false)
      end
    end

    context "as teacher from different org" do
      let(:current_user) { build_stubbed(:user, :teacher, organization: other_org) }

      it "forbids #{action}" do
        expect(subject.public_send("#{action}?")).to eq(false)
      end
    end

    context "as student" do
      let(:current_user) { build_stubbed(:user, organization: org) }

      it "forbids #{action}" do
        expect(subject.public_send("#{action}?")).to eq(false)
      end
    end

    context "as guest (nil user)" do
      let(:current_user) { nil }

      it "forbids #{action}" do
        expect(subject.public_send("#{action}?")).to eq(false)
      end
    end
  end

  %i[create update destroy].each do |action|
    describe "#{action}?" do
      it_behaves_like "create/update/destroy for resource", action
    end
  end

  describe "Scope" do
    subject { described_class::Scope.new(current_user, Resource).resolve }

    let!(:resource_in_org) { create(:resource, course: create(:course, organization: org)) }
    let!(:resource_in_other_org) { create(:resource, course: create(:course, organization: other_org)) }

    context "as global_admin" do
      let(:current_user) { build_stubbed(:user, :global_admin) }

      it "returns all resources" do
        expect(subject).to include(resource_in_org, resource_in_other_org)
      end
    end

    context "as org_admin" do
      let(:current_user) { build_stubbed(:user, :org_admin, organization: org) }

      it "returns only resources from the same org" do
        expect(subject).to include(resource_in_org)
        expect(subject).not_to include(resource_in_other_org)
      end
    end

    context "as teacher" do
      let(:current_user) { build_stubbed(:user, :teacher, organization: org) }

      it "returns only resources from the same org" do
        expect(subject).to include(resource_in_org)
        expect(subject).not_to include(resource_in_other_org)
      end
    end

    context "as student" do
      let(:current_user) { create(:user, organization: org) }
      let!(:resource_in_org) do
        course = create(:course, organization: org)
        create(:enrollment, user: current_user, course: course)
        create(:resource, course: course)
      end

      let!(:resource_in_other_org) do
        other_course = create(:course, organization: other_org)
        create(:resource, course: other_course)
      end

      subject { described_class::Scope.new(current_user, Resource).resolve }

      it "returns only resources where student is enrolled" do
        expect(subject).to include(resource_in_org)
        expect(subject).not_to include(resource_in_other_org)
      end
    end

    context "as nil user" do
      let(:current_user) { nil }

      it "returns no resources" do
        expect(subject).to be_empty
      end
    end
  end
end
