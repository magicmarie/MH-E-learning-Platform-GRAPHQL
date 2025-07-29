class UserProfilePolicy < ApplicationPolicy
  def show?
    return false if user.nil?

    user_owns_profile? || user.global_admin? || user.org_admin? || user.teacher?
  end

  def update?
    return false if user.nil?

    user_owns_profile? || user.global_admin? || user.org_admin?
  end

  class Scope < Scope
    def resolve
      return scope.none if user.nil?

      if user.global_admin?
        scope.all
      elsif user.org_admin? || user.teacher?
        scope.joins(:user).where(users: { organization_id: user.organization_id })
        .where.not(users: { role: Constants::Roles::ROLES[:global_admin] })

      else
        scope.where(user_id: user.id)
      end
    end
  end

  private

  def user_owns_profile?
    record.user_id == user.id
  end
end
