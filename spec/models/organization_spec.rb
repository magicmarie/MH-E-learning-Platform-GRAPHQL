require 'rails_helper'

RSpec.describe Organization, type: :model do
  describe "associations" do
    it { should have_many(:users) }
  end

  describe "validations" do
    subject(:organization) { build(:organization) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:organization_code) }

    context "organization_code uniqueness" do
      let!(:existing_org) { create(:organization, organization_code: "ABC123") }
      let(:duplicate_org) { build(:organization, organization_code: "ABC123") }

      it "is not valid when duplicated" do
        expect(duplicate_org).not_to be_valid
        expect(duplicate_org.errors[:organization_code]).to include("has already been taken")
      end
    end

    context "organization_code format" do
      it "allows valid format" do
        organization.organization_code = "Abc-12"
        expect(organization).to be_valid
      end

      it "rejects invalid characters" do
        organization.organization_code = "abc@12"
        expect(organization).not_to be_valid
        expect(organization.errors[:organization_code]).to include("only allows letters, numbers, dashes, and underscores")
      end

      it "rejects incorrect length" do
        short_code = build(:organization, organization_code: "abc12")   # 5 chars
        long_code  = build(:organization, organization_code: "abcdefg") # 7 chars

        expect(short_code).not_to be_valid
        expect(short_code.errors[:organization_code]).to include("must be exactly 6 characters long")

        expect(long_code).not_to be_valid
        expect(long_code.errors[:organization_code]).to include("must be exactly 6 characters long")
      end
    end
  end
end
