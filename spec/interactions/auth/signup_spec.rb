RSpec.describe Auth::Signup do
  let(:organization) { create(:organization) }
  let(:email) { "newuser@example.com" }
  let(:password) { "password123" }
  let(:role) { "student" }

  subject(:signup) do
    described_class.run(
      email: email,
      password: password,
      organization_id: organization_id,
      role: role
    )
  end

  before do
    allow(JsonWebToken).to receive(:encode).and_return("mock_token")
    allow(UserSerializer).to receive(:new).and_wrap_original do |_, user|
      double(as_json: { id: user.id, email: user.email, role: user.role })
    end
  end

  context "when organization does not exist" do
    let(:organization_id) { 9999 }  # non-existent

    it "fails with organization not found" do
      expect(signup).to be_invalid
      expect(signup.errors.full_messages).to include("Organization not found")
    end
  end

  context "when organization exists" do
    let(:organization_id) { organization.id }

    context "and user data is valid" do
      it "creates the user and returns token + serialized user" do
        expect { signup }.to change(User, :count).by(1)

        expect(signup).to be_valid
        expect(signup.result[:token]).to eq("mock_token")
        expect(signup.result[:user]).to include(email: email, role: Constants::Roles::ROLES[:student])
      end
    end

    context "and user data is invalid" do
      let(:email) { "" }  # invalid email

      it "fails and merges user errors" do
        expect { signup }.not_to change(User, :count)

        expect(signup).to be_invalid
        expect(signup.errors.full_messages).to include("Email can't be blank")
      end
    end
  end
end
