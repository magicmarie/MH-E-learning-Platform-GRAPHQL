# spec/models/resource_spec.rb
require 'rails_helper'

RSpec.describe Resource, type: :model do
  describe "associations" do
    it { should belong_to(:course) }
  end

  describe "attachments" do
    it "can attach a file" do
      resource = create(:resource)

      expect(resource.file).to be_attached
    end

    it "destroys the file when resource is destroyed" do
      resource = create(:resource)

      expect { resource.destroy }.to change(ActiveStorage::Attachment, :count).by(-1)
    end
  end
end
