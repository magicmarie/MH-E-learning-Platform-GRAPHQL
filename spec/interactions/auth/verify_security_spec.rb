RSpec.describe Auth::VerifySecurity do
  let(:email) { "admin@example.com" }
  let(:security_answer) { "correct-answer" }
  let(:user) { instance_double(User, id: 123, email: email) }

  subject { described_class.run(email: email, security_answer: security_answer) }

  before do
    allow(User).to receive(:find_by).with(email: email).and_return(user)
    allow(JsonWebToken).to receive(:encode).and_return("mock_token")
    allow(UserSerializer).to receive(:new).and_return(double(as_json: { id: 123, email: email }))
  end

  context "when user is not found" do
    let(:user) { nil }

    it "fails with unauthorized error" do
      expect(subject).to be_invalid
      expect(subject.errors.full_messages).to include("Unauthorized")
    end
  end

  context "when user is not a global admin" do
    before { allow(user).to receive(:global_admin?).and_return(false) }

    it "fails with unauthorized error" do
      expect(subject).to be_invalid
      expect(subject.errors.full_messages).to include("Unauthorized")
    end
  end

  context "when user is deactivated" do
    before do
      allow(user).to receive(:global_admin?).and_return(true)
      allow(user).to receive(:active?).and_return(false)
    end

    it "fails with deactivation error" do
      expect(subject).to be_invalid
      expect(subject.errors.full_messages).to include("Account is deactivated")
    end
  end

  context "when security answer is incorrect" do
    before do
      allow(user).to receive(:global_admin?).and_return(true)
      allow(user).to receive(:active?).and_return(true)
      allow(user).to receive(:correct_security_answer?).with(security_answer).and_return(false)
    end

    it "fails with incorrect answer error" do
      expect(subject).to be_invalid
      expect(subject.errors.full_messages).to include("Incorrect security answer")
    end
  end

  context "when everything is valid" do
    before do
      allow(user).to receive(:global_admin?).and_return(true)
      allow(user).to receive(:active?).and_return(true)
      allow(user).to receive(:correct_security_answer?).with(security_answer).and_return(true)
    end

    it "returns a token and serialized user" do
      expect(subject).to be_valid
      expect(subject.result).to eq({
        token: "mock_token",
        user: { id: 123, email: email }
      })
    end
  end
end
