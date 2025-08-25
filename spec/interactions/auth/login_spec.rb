RSpec.describe Auth::Login do
  let(:organization) { create(:organization) }
  let(:password) { "password123" }
  let(:email) { "user@example.com" }
  let(:security_answer) { "Roxy" }

  let(:user) do
    create(:user,
           email: email,
           password: password,
           organization: organization,
           active: true)
  end

  let(:global_admin) do
    create(:user, :global_admin,
           email: "admin@example.com",
           password: password)
  end

  before do
    allow(JsonWebToken).to receive(:encode).and_return("mock_jwt_token")
    allow(ActiveModelSerializers::SerializableResource).to receive(:new).and_wrap_original do |_, user|
      double(as_json: { id: user.id, email: user.email, role: user.role })
    end
  end

  describe "#execute" do
    context "with valid credentials" do
      context "when organization_id is provided for regular user" do
        subject(:login) do
          described_class.run(
            email: user.email,
            password: password,
            organization_id: organization.id
          )
        end

        it "returns success response with token and user" do
          expect(login).to be_valid
          expect(login.result[:status]).to eq(:ok)
          expect(login.result[:token]).to eq("mock_jwt_token")
          expect(login.result[:user]).to be_present
        end

        it "encodes JWT with correct user_id" do
          login
          expect(JsonWebToken).to have_received(:encode).with(user_id: user.id)
        end

        it "serializes the user" do
          login
          expect(ActiveModelSerializers::SerializableResource).to have_received(:new).with(user)
        end
      end

      context "when regular user tries to login without organization_id" do
        subject(:login) do
          described_class.run(
            email: user.email,
            password: password
          )
        end

        it "fails with organization_id required error" do
          expect(login).to be_invalid
          expect(login.errors.full_messages).to include("Organization is required")
        end
      end

      context "when global admin logs in without organization_id" do
        subject(:login) do
          described_class.run(
            email: global_admin.email,
            password: password
          )
        end

        before do
          allow(User.global_admins).to receive(:exists?).with(email: global_admin.email).and_return(true)
        end

        it "returns MFA prompt (no organization_id needed)" do
          expect(login).to be_valid
          expect(login.result[:status]).to eq(:partial_content)
          expect(login.result[:message]).to eq("MFA required")
        end
      end
    end

    context "with invalid credentials" do
      subject(:login) do
        described_class.run(
          email: user.email,
          password: "wrong_password",
          organization_id: organization.id
        )
      end

      it "returns unauthorized error" do
        expect(login).to be_invalid
        expect(login.result[:status]).to eq(:unauthorized)
        expect(login.result[:error]).to eq("Invalid credentials")
        expect(login.errors.full_messages).to include("Invalid credentials")
      end
    end

    context "when user does not exist" do
      subject(:login) do
        described_class.run(
          email: "nonexistent@example.com",
          password: password,
          organization_id: organization.id
        )
      end

      it "returns unauthorized error" do
        expect(login).to be_invalid
        expect(login.result[:status]).to eq(:unauthorized)
        expect(login.result[:error]).to eq("Invalid credentials")
        expect(login.errors.full_messages).to include("Invalid credentials")
      end
    end

    context "when user is inactive" do
      let(:inactive_user) do
        create(:user, :deactivated,
               email: "inactive@example.com",
               password: password,
               organization: organization)
      end

      subject(:login) do
        described_class.run(
          email: inactive_user.email,
          password: password,
          organization_id: organization.id
        )
      end

      it "returns unauthorized error for deactivated account" do
        expect(login).to be_invalid
        expect(login.result[:status]).to eq(:unauthorized)
        expect(login.result[:error]).to eq("Account is deactivated")
        expect(login.errors.full_messages).to include("Account is deactivated")
      end
    end

    context "with global admin user" do
      context "without security answer (blank or nil)" do
        it "returns MFA prompt when blank" do
          login = described_class.run(email: global_admin.email, password: password, security_answer: "")
          expect(login).to be_valid
          expect(login.result[:status]).to eq(:partial_content)
          expect(login.result[:message]).to eq("MFA required")
        end

        it "returns MFA prompt when nil" do
          login = described_class.run(email: global_admin.email, password: password, security_answer: nil)
          expect(login).to be_valid
          expect(login.result[:status]).to eq(:partial_content)
          expect(login.result[:message]).to eq("MFA required")
        end
      end

      context "with correct security answer" do
        subject(:login) do
          described_class.run(
            email: global_admin.email,
            password: password,
            security_answer: security_answer
          )
        end

        before do
          allow(User.global_admins).to receive(:find_by).with(email: global_admin.email).and_return(global_admin)
        end

        it "returns success response" do
          allow(global_admin).to receive(:correct_security_answer?).with(security_answer).and_return(true)

          expect(login).to be_valid
          expect(login.result[:status]).to eq(:ok)
          expect(login.result[:token]).to eq("mock_jwt_token")
          expect(login.result[:user]).to be_present
        end
      end

      context "with incorrect security answer" do
        subject(:login) do
          described_class.run(
            email: global_admin.email,
            password: password,
            security_answer: "wrong answer"
          )
        end

        before do
          allow(global_admin).to receive(:correct_security_answer?).with("wrong answer").and_return(false)
          allow(User.global_admins).to receive(:find_by).with(email: global_admin.email).and_return(global_admin)
        end

        it "returns unauthorized error" do
          expect(login).to be_invalid
          expect(login.result[:status]).to eq(:unauthorized)
          expect(login.result[:error]).to eq("Incorrect security answer")
          expect(login.errors.full_messages).to include("Incorrect security answer")
        end
      end
    end

    context "when organization_id is provided but user belongs to different org" do
      let(:other_organization) { create(:organization) }

      subject(:login) do
        described_class.run(
          email: user.email,
          password: password,
          organization_id: other_organization.id
        )
      end

      it "returns unauthorized error" do
        expect(login).to be_invalid
        expect(login.result[:status]).to eq(:unauthorized)
        expect(login.result[:error]).to eq("Invalid credentials")
        expect(login.errors.full_messages).to include("Invalid credentials")
      end
    end
  end

  describe "#find_user" do
    let(:login_instance) { described_class.new(email: user.email, password: password) }

    context "when organization_id is present" do
      before { login_instance.organization_id = organization.id }

      it "finds user by email and organization_id" do
        expect(User).to receive(:find_by).with(email: user.email, organization_id: organization.id)
        login_instance.send(:find_user)
      end
    end

    context "when organization_id is not present" do
      it "finds global admin by email through scope" do
        allow(User.global_admins).to receive(:find_by).with(email: global_admin.email).and_return(global_admin)

        login_instance = described_class.new(email: global_admin.email, password: password)
        expect(login_instance.send(:find_user)).to eq(global_admin)
      end
    end
  end

  describe "input validation" do
    it "requires email" do
      result = described_class.run(password: password)
      expect(result).to be_invalid
      expect(result.errors.full_messages).to include("Email is required")
    end

    it "requires password" do
      result = described_class.run(email: email)
      expect(result).to be_invalid
      expect(result.errors.full_messages).to include("Password is required")
    end

    it "requires organization_id for non-global admin users" do
      result = described_class.run(email: "regular@example.com", password: password)
      expect(result).to be_invalid
      expect(result.errors.full_messages).to include("Organization is required")
    end

    it "does not require organization_id for global admin" do
      allow(User.global_admins).to receive(:exists?).with(email: global_admin.email).and_return(true)
      result = described_class.run(email: global_admin.email, password: password)
      expect(result.inputs[:email]).to eq(global_admin.email)
      expect(result.inputs[:password]).to eq(password)
      expect(result.inputs[:organization_id]).to be_nil
      expect(result.inputs[:security_answer]).to be_nil
    end
  end
end
