# frozen_string_literal: true

class AssignmentPolicy < ApplicationPolicy
  def index?
    global_admin_or_teacher_or_org_admin? || enrolled_student?
  end

  def show?
    global_admin_or_teacher_or_org_admin? || enrolled_student?
  end

  def create?
    global_admin_or_teacher_or_org_admin?
  end

  def update?
    global_admin_or_teacher_or_org_admin?
  end

  def destroy?
    global_admin_or_teacher_or_org_admin?
  end

  private

  def global_admin_or_teacher_or_org_admin?
    return false unless user

    user.global_admin? || ((user.org_admin? || user.teacher?)  && same_organization?)
  end

  def enrolled_student?
    return false unless user&.student?
    record.course.enrollments.exists?(user_id: user.id)
  end

  def same_organization?
    record.course.organization_id == user.organization_id
  end

  class Scope < Scope
    def resolve
      return scope.none unless user
      return scope.all if user.global_admin?
      return scope.joins(:course).where(courses: { organization_id: user.organization_id }) if user.teacher? || user.org_admin?
      return scope.joins(course: :enrollments).where(enrollments: { user_id: user.id }) if user.student?

      scope.none
    end
  end
end
