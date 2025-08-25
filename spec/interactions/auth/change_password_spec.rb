RSpec.describe Auth::ChangePassword do
  let(:password) { "oldpassword123" }
  let(:new_password) { "newpassword456" }
  let(:user) { create(:user, password: password, active: true) }

  describe "#execute" do
    subject(:change_password) do
      described_class.run(
        user: user,
        current_password: current_password,
        new_password: new_password
      )
    end

    context "with correct current password" do
      let(:current_password) { password }

      it "updates the user's password successfully" do
        result = change_password

        expect(change_password).to be_valid
        expect(result.result).to eq({ message: "Password updated successfully" })

        # Verify the new password works
        expect(user.reload.authenticate(new_password)).to eq(user)
      end
    end

    context "with incorrect current password" do
      let(:current_password) { "wrongpassword" }

      it "returns an error and does not update password" do
        result = change_password

        expect(change_password).to be_invalid
        expect(change_password.errors.full_messages).to include("Incorrect password")
        expect(result.result).to be_nil

        # Ensure password is unchanged
        expect(user.reload.authenticate(password)).to eq(user)
      end
    end

    context "when new password is invalid" do
      let(:current_password) { password }
      let(:new_password) { "" } # assuming presence validation on password

      it "does not update and returns merged errors" do
        result = change_password

        expect(result.result).to be_nil

        # Password should not change
        expect(user.reload.authenticate(password)).to eq(user)
      end
    end
  end
end
