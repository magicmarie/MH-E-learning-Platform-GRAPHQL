# frozen_string_literal: true

class ResourcePolicy < ApplicationPolicy
  def index?
    return false unless user

    if user.student?
      enrolled_in_course?
    else
      user.global_admin? || org_scoped_creator?
    end
  end

  def show?
    index?
  end

  def create?
    return false unless user

    user.global_admin? || org_scoped_creator?
  end

  def update?
    return false unless user

    user.global_admin? || org_scoped_creator?
  end

  def destroy?
    return false unless user

    user.global_admin? || org_scoped_creator?
  end

  class Scope < ResourcePolicy::Scope
    def resolve
      return scope.none unless user

      if user.global_admin?
        scope.all
      elsif user.student?
        scope.joins(course: :enrollments)
             .where(enrollments: { user_id: user.id })
      else
        scope.joins(:course).where(courses: { organization_id: user.organization_id })
      end
    end
  end

  private

  def org_scoped_creator?
    (user.org_admin? || user.teacher?) &&
      record.course.organization_id == user.organization_id
  end

  def enrolled_in_course?
    record.course.enrollments.exists?(user_id: user.id)
  end
end
