require 'rails_helper'

RSpec.describe UserProfile, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    let(:user) { create(:user) }
    subject { user.user_profile }  # existing profile

    it { should validate_length_of(:org_member_id).is_at_most(6) }

    it "allows nil org_member_id" do
      subject.org_member_id = nil
      expect(subject).to be_valid
    end

    context "org_member_id uniqueness" do
      let!(:user1) { create(:user) }
      let!(:existing_profile) do
        profile = user1.user_profile
        profile.update!(org_member_id: "ABC123")
        profile
      end

      let!(:user2) { create(:user) }
      let(:duplicate_profile) { user2.user_profile }

      before do
        duplicate_profile.org_member_id = "ABC123"  # duplicate org_member_id
      end

      it "is not valid if org_member_id is duplicated" do
        expect(duplicate_profile).not_to be_valid
        expect(duplicate_profile.errors[:org_member_id]).to include("has already been taken")
      end
    end
  end

  describe "attachments" do
    let(:user) { create(:user) }
    let(:profile) { user.user_profile }

    it "can attach an avatar" do
      profile.avatar.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/avatar.jpg")),
        filename: "avatar.png",
        content_type: "image/png"
      )

      expect(profile.avatar).to be_attached
    end
  end
end
