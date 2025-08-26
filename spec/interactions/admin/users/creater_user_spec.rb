RSpec.describe Admin::Users::CreateUser do
  let(:organization) { create(:organization) }
  let(:current_user) { create(:user, :org_admin, organization: organization) }
  let(:email) { "newuser@example.com" }

  before do
    allow(JsonWebToken).to receive(:encode).and_return("mock_token")
    allow(UserMailer).to receive_message_chain(:welcome_user, :deliver_now)
  end

  describe "#execute" do
    subject(:create_user) do
      described_class.run(
        current_user: current_user,
        email: email,
        incoming_role: incoming_role,
        organization_id: organization.id
      )
    end

    context "with valid role" do
      let(:incoming_role) { :student }

      it "creates the user and sends welcome email" do
        user = create_user.result

        expect(user).to be_a(User)
        expect(user.email).to eq(email)
        expect(user.role).to eq(Constants::Roles::ROLES[:student])
        expect(user.organization).to eq(organization)
      end
    end

    context "with global_admin role" do
      let(:incoming_role) { :global_admin }

      it "does not create the user and adds an error" do
        result = create_user.result

        expect(result).to be_nil
        expect(create_user.errors.full_messages).to include("Cannot create global_admin")
      end
    end

    context "with disallowed role" do
      let(:incoming_role) { :some_invalid_role }

      it "does not create the user and adds an error" do
        result = create_user.result

        expect(result).to be_nil
        expect(create_user.errors.full_messages).to include("Incoming role is not included in the list")
      end
    end

    context "when organization does not exist" do
      let(:incoming_role) { :student }

      subject(:create_user) do
        described_class.run(
          current_user: current_user,
          email: email,
          incoming_role: incoming_role,
          organization_id: 0 # invalid ID
        )
      end

      it "does not create the user and adds an error" do
        result = create_user.result

        expect(result).to be_nil
        expect(create_user.errors.full_messages).to include("Organization not found")
      end
    end
  end
end
