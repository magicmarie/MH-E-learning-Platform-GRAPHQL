# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserProfilePolicy do
  subject { described_class.new(current_user, user_profile) }

  let(:org) { create(:organization) }
  let(:other_org) { create(:organization) }
  let(:user) { create(:user, organization: org) }
  let(:user_profile) { user.user_profile }

  describe '#show?' do
    context 'when user owns the profile' do
      let(:current_user) { user }

      it 'permits access' do
        expect(subject.show?).to eq(true)
      end
    end

    context 'when global admin' do
      let(:current_user) { create(:user, :global_admin) }

      it 'permits access' do
        expect(subject.show?).to eq(true)
      end
    end

    context 'when org admin in same org' do
      let(:current_user) { create(:user, :org_admin, organization: org) }

      it 'permits access' do
        expect(subject.show?).to eq(true)
      end
    end

    context 'when teacher in same org' do
      let(:current_user) { create(:user, :teacher, organization: org) }

      it 'permits access' do
        expect(subject.show?).to eq(true)
      end
    end

    context 'when student not owning profile' do
      let(:current_user) { create(:user, organization: org) }

      it 'forbids access' do
        expect(subject.show?).to eq(false)
      end
    end

    context 'when nil user' do
      let(:current_user) { nil }

      it 'forbids access' do
        expect(subject.show?).to eq(false)
      end
    end
  end

  describe '#update?' do
    context 'when user owns the profile' do
      let(:current_user) { user }

      it 'permits update' do
        expect(subject.update?).to eq(true)
      end
    end

    context 'when global admin' do
      let(:current_user) { create(:user, :global_admin) }

      it 'permits update' do
        expect(subject.update?).to eq(true)
      end
    end

    context 'when org admin in same org' do
      let(:current_user) { create(:user, :org_admin, organization: org) }

      it 'permits update' do
        expect(subject.update?).to eq(true)
      end
    end

    context 'when teacher' do
      let(:current_user) { create(:user, :teacher, organization: org) }

      it 'forbids update' do
        expect(subject.update?).to eq(false)
      end
    end

    context 'when student not owning profile' do
      let(:current_user) { create(:user, organization: org) }

      it 'forbids update' do
        expect(subject.update?).to eq(false)
      end
    end

    context 'when nil user' do
      let(:current_user) { nil }

      it 'forbids update' do
        expect(subject.update?).to eq(false)
      end
    end
  end

  describe 'Scope' do
    subject { described_class::Scope.new(current_user, UserProfile).resolve }

    let!(:user1) { create(:user, organization: org) }
    let!(:user2) { create(:user, organization: other_org) }
    let!(:global_admin_user) { create(:user, :global_admin) }
    let(:profile1) { user1.user_profile }
    let(:profile2) { user2.user_profile }

    context 'as global admin' do
      let(:current_user) { global_admin_user }

      it 'returns all profiles' do
        expect(subject).to include(profile1, profile2)
      end
    end

    context 'as org admin' do
      let(:current_user) { create(:user, :org_admin, organization: org) }

      it 'returns only same-org non-global_admin profiles' do
        expect(subject).to include(profile1)
        expect(subject).not_to include(profile2)
      end
    end

    context 'as teacher' do
      let(:current_user) { create(:user, :teacher, organization: org) }

      it 'returns only same-org non-global_admin profiles' do
        expect(subject).to include(profile1)
        expect(subject).not_to include(profile2)
      end
    end

    context 'as student' do
      let(:current_user) { user1 }

      it 'returns only their own profile' do
        expect(subject).to contain_exactly(profile1)
      end
    end

    context 'as nil user' do
      let(:current_user) { nil }

      it 'returns nothing' do
        expect(subject).to be_empty
      end
    end
  end
end
