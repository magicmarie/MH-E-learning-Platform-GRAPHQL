RSpec.describe UsersController, type: :request do
  let(:organization) { create(:organization) }
  let(:current_user) { create(:user, :org_admin, organization: organization) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:authorize_request).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(current_user)
    allow_any_instance_of(ApplicationController).to receive(:authorize).and_return(true)
  end

  describe "POST /users" do
    let(:params) { { email: "newuser@example.com", role: "student" } }

    context "when creation succeeds" do
      let(:interaction) { double("Users::CreateUser", valid?: true, result: { id: 1, email: "newuser@example.com" }) }

      before do
        allow(Users::CreateUser).to receive(:run).and_return(interaction)
      end

      it "returns created user JSON" do
        post "/users", params: params
        expect(response).to have_http_status(:created)
        expect(response.parsed_body).to eq({ "id" => 1, "email" => "newuser@example.com" })
      end
    end

    context "when creation fails" do
      let(:interaction) { double("Users::CreateUser", valid?: false, errors: double(full_messages: ["Email taken"])) }

      before do
        allow(Users::CreateUser).to receive(:run).and_return(interaction)
      end

      it "returns errors" do
        post "/users", params: params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body).to eq({ "errors" => ["Email taken"] })
      end
    end
  end

  describe "POST /users/bulk_create" do
    let(:file) do
      StringIO.new(<<~CSV)
        email,name
        user1@example.com,User One
        user2@example.com,User Two
      CSV
    end
    let(:params) { { file: file, role: "student" } }

    context "when bulk creation succeeds" do
      let(:created_users) { [build(:user, email: "user1@example.com"), build(:user, email: "user2@example.com")] }
      let(:failed_users) { [] }
      let(:interaction) { double("Users::BulkCreateUsers", valid?: true, result: { created: created_users, failed: failed_users }) }

      before do
        allow(Users::BulkCreateUsers).to receive(:run).and_return(interaction)
        allow(ActiveModelSerializers::SerializableResource).to receive(:new).and_return(created_users.map(&:as_json))
      end

      it "returns created and failed results" do
        post "/users/bulk_create", params: params
        expect(response).to have_http_status(:multi_status)
        expect(response.parsed_body["created"]).to all(include("email"))
        expect(response.parsed_body["failed"]).to eq([])
      end
    end

    context "when bulk creation fails" do
      let(:interaction) { double("Users::BulkCreateUsers", valid?: false, errors: double(full_messages: ["Invalid CSV"])) }

      before do
        allow(Users::BulkCreateUsers).to receive(:run).and_return(interaction)
      end

      it "returns errors" do
        post "/users/bulk_create", params: params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body).to eq({ "errors" => ["Invalid CSV"] })
      end
    end
  end
end

