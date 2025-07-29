# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AssessmentPolicy do
  subject { described_class.new(current_user, assessment) }

  let(:organization) { create(:organization) }
  let(:other_org) { create(:organization) }
  let(:course) { create(:course, organization: organization) }
  let(:enrollment) { create(:enrollment, course: course, user: enrolled_student) }
  let(:assessment) { create(:assessment, enrollment: enrollment) }
  let(:enrolled_student) { create(:user, organization: organization) }

  shared_examples "permits actions" do |*actions|
    actions.each do |action|
      it "permits #{action}" do
        expect(subject.public_send("#{action}?")).to eq(true)
      end
    end
  end

  shared_examples "forbids actions" do |*actions|
    actions.each do |action|
      it "forbids #{action}" do
        expect(subject.public_send("#{action}?")).to eq(false)
      end
    end
  end

  describe "Permissions" do
    context "as global_admin" do
      let(:current_user) { build_stubbed(:user, :global_admin) }

      include_examples "permits actions", :index, :show, :create, :update, :destroy
    end

    context "as org_admin from same org" do
      let(:current_user) { build_stubbed(:user, :org_admin, organization: organization) }

      include_examples "permits actions", :index, :show, :create, :update, :destroy
    end

    context "as org_admin from different org" do
      let(:current_user) { build_stubbed(:user, :org_admin, organization: other_org) }

      include_examples "forbids actions", :index, :show, :create, :update, :destroy
    end

    context "as teacher from same org" do
      let(:current_user) { build_stubbed(:user, :teacher, organization: organization) }

      include_examples "permits actions", :index, :show, :create, :update, :destroy
    end

    context "as teacher from different org" do
      let(:current_user) { build_stubbed(:user, :teacher, organization: other_org) }

      include_examples "forbids actions", :index, :show, :create, :update, :destroy
    end

    context "as enrolled student" do
      let(:current_user) { enrolled_student }

      include_examples "permits actions", :index, :show, :update
      include_examples "forbids actions", :create, :destroy
    end

    context "as other student not enrolled" do
      let(:current_user) { build_stubbed(:user, organization: organization) }

      include_examples "forbids actions", :index, :show, :create, :update, :destroy
    end

    context "as guest (nil user)" do
      let(:current_user) { nil }

      include_examples "forbids actions", :index, :show, :create, :update, :destroy
    end
  end

  describe "Scope" do
    subject { described_class::Scope.new(current_user, Assessment).resolve }

    let!(:assessment_in_org) { create(:assessment, enrollment: create(:enrollment, course: course, user: enrolled_student)) }
    let!(:assessment_in_other_org) do
      create(:assessment, enrollment: create(:enrollment, course: create(:course, organization: other_org)))
    end

    context "as global_admin" do
      let(:current_user) { create(:user, :global_admin) }

      it "returns all assessments" do
        expect(subject).to include(assessment_in_org, assessment_in_other_org)
      end
    end

    context "as org_admin" do
      let(:current_user) { create(:user, :org_admin, organization: organization) }

      it "returns assessments from same org only" do
        expect(subject).to include(assessment_in_org)
        expect(subject).not_to include(assessment_in_other_org)
      end
    end

    context "as teacher" do
      let(:current_user) { create(:user, :teacher, organization: organization) }

      it "returns assessments from same org only" do
        expect(subject).to include(assessment_in_org)
        expect(subject).not_to include(assessment_in_other_org)
      end
    end

    context "as enrolled student" do
      let(:current_user) { enrolled_student }

      it "returns only assessments tied to their enrollment" do
        expect(subject).to include(assessment_in_org)
        expect(subject).not_to include(assessment_in_other_org)
      end
    end

    context "as other student" do
      let(:current_user) { create(:user, organization: organization) }

      it "returns no assessments" do
        expect(subject).not_to include(assessment_in_org)
      end
    end

    context "as guest" do
      let(:current_user) { nil }

      it "returns no assessments" do
        expect(subject).to be_empty
      end
    end
  end
end
