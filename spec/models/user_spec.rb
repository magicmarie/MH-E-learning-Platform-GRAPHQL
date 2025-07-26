require 'rails_helper'

RSpec.describe User, type: :model do
  describe "associations" do
    it { should belong_to(:deactivated_by_user).class_name("User").with_foreign_key("deactivated_by_id").optional }
    it { should belong_to(:activated_by_user).class_name("User").with_foreign_key("activated_by_id").optional }
    it { should have_many(:enrollments) }
    it { should have_many(:courses).through(:enrollments) }
    it { should have_one(:user_profile).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:role) }

    describe "email uniqueness scoped to organization" do
      let(:organization) { create(:organization) }
      let!(:existing_user) { create(:user, :org_admin, email: "foo@example.com", organization: organization) }
      let(:duplicate_user) { build(:user, :org_admin, email: "foo@example.com", organization: organization) }

      it "is invalid when duplicated" do
        expect(duplicate_user).not_to be_valid
        expect(duplicate_user.errors[:email]).to include("has already been taken")
      end
    end

    it "validates inclusion of role" do
      user = build(:user, role: 9)
      expect(user).not_to be_valid
      expect(user.errors[:role]).to include("is not included in the list")
    end

    context "organization requirement" do
      it "requires organization unless global admin" do
        user = build(:user, :org_admin, organization: nil)
        expect(user).not_to be_valid
        expect(user.errors[:organization]).to include("can't be blank")
      end

      it "does not require organization for global admin" do
        user = build(:user, :global_admin, organization: nil)
        expect(user).to be_valid
      end
    end

    context "security fields for global admin" do
      let(:user) { build(:user, :global_admin, security_question: nil, security_answer: nil) }

      it "requires security_question and security_answer" do
        expect(user).not_to be_valid
        expect(user.errors[:security_question]).to include("can't be blank")
        expect(user.errors[:security_answer_digest]).to include("can't be blank")
      end
    end
  end

  describe "custom validation: only_one_global_admin" do
    it "disallows more than one global admin" do
      create(:user, :global_admin)
      another = build(:user, :global_admin)
      expect(another).not_to be_valid
      expect(another.errors[:role]).to include("There can be only one global admin")
    end

    it "allows first global admin" do
      expect(build(:user, :global_admin)).to be_valid
    end
  end

  describe "secure password and security answer" do
    let(:user) { create(:user, password: "secret123") }

    it "authenticates password correctly" do
      expect(user.authenticate("secret123")).to eq(user)
      expect(user.authenticate("wrong")).to be_falsey
    end

    it "authenticates security answer" do
      admin = create(:user, :global_admin, security_answer: "rosebud")
      expect(admin.correct_security_answer?("rosebud")).to eq(admin)
      expect(admin.correct_security_answer?("wrong")).to be false
    end
  end

  describe "scopes" do
    let!(:admin) { create(:user, :global_admin) }
    let!(:user) { create(:user) }

    it "returns global admins only" do
      expect(User.global_admins).to contain_exactly(admin)
    end
  end

  describe "role predicate methods" do
    it "returns true for matching role method" do
      expect(build(:user, :teacher).teacher?).to be true
      expect(build(:user, :org_admin).org_admin?).to be true
      expect(build(:user).student?).to be true
      expect(build(:user, :global_admin).global_admin?).to be true
    end

    it "returns false for non-matching roles" do
      user = build(:user)
      expect(user.teacher?).to be false
      expect(user.global_admin?).to be false
      expect(user.org_admin?).to be false
    end
  end

  describe "callbacks" do
    it "creates a user_profile after create unless global admin" do
      user = create(:user)
      expect(user.user_profile).to be_present
    end

    it "does not create a profile for global admin" do
      user = create(:user, :global_admin)
      expect(user.user_profile).to be_nil
    end
  end
end
