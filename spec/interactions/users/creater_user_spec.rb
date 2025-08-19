RSpec.describe Users::CreateUser, type: :interaction do
  let(:organization) { create(:organization) }
  let!(:current_user) { create(:user, :org_admin, organization: organization) }
  let(:email) { 'new_user@example.com' }
  let(:incoming_role) { :teacher }

  subject do
    described_class.new(
      current_user: current_user,
      email: email,
      incoming_role: incoming_role
    )
  end

  describe 'validations' do
    it 'is invalid if role is not in ROLES' do
      result = described_class.run(current_user: current_user, email: email, incoming_role: :invalid_role)
      expect(result).to be_invalid
      expect(result.errors[:incoming_role]).to include('is not included in the list')
    end
  end

  describe '#execute' do
    context 'with allowed role' do
      %i[teacher student].each do |role|
        it "creates a user with #{role} role" do
          expect {
            result = described_class.run(current_user: current_user, email: email, incoming_role: role)
            expect(result).to be_valid
            expect(result.result.email).to eq(email)
            expect(result.result.role).to eq(Constants::Roles::ROLES[role])
          }.to change(User, :count).by(1)
        end
      end
    end

    context 'when creating a disallowed admin role' do
      %i[global_admin org_admin].each do |role|
        it "returns error for #{role}" do
          result = described_class.run(current_user: current_user, email: email, incoming_role: role)
          expect(result).to be_invalid
          expect(result.errors[:base]).to include("Org admins cannot create '#{role}' users")
        end
      end
    end

    context 'when user fails to save' do
      before do
        allow_any_instance_of(User).to receive(:save).and_return(false)
        allow_any_instance_of(User).to receive(:errors).and_return(
          ActiveModel::Errors.new(User.new).tap { |e| e.add(:email, 'is invalid') }
        )
      end

      it 'merges user errors' do
        result = described_class.run(current_user: current_user, email: email, incoming_role: :teacher)
        expect(result).to be_invalid
        expect(result.errors[:email]).to include('is invalid')
      end
    end

    context 'welcome email' do
      it 'creates user and sends welcome email' do
         allow(JsonWebToken).to receive(:encode).and_return('mock_token')

        # Mock the send_welcome_email method to avoid URL issues entirely
        expect(subject).to receive(:send_welcome_email).with(anything, anything) do |user, temp_password|
          UserMailer.welcome_user(user, temp_password, 'http://test.com/reset').deliver_now
        end

        user = subject.execute

        expect(user).not_to be_nil
        expect(user).to be_persisted
      end


      it 'logs error if email sending fails' do
        allow(UserMailer).to receive(:welcome_user).and_raise(StandardError.new('SMTP error'))
        logger = double('Logger')
        allow(Rails).to receive(:logger).and_return(logger)
        expect(logger).to receive(:error).with(/Failed to send welcome email/)

        result = described_class.run(current_user: current_user, email: email, incoming_role: :student)
        expect(result).to be_valid
      end
    end
  end
end
