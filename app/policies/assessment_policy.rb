# frozen_string_literal: true

class AssessmentPolicy < ApplicationPolicy
  def index?
    global_admin_or_teacher_or_org_admin? || student_owns_enrollment?
  end

  def show?
    global_admin_or_teacher_or_org_admin? || student_owns_enrollment?
  end

  def create?
    global_admin_or_teacher_or_org_admin?
  end

  def update?
    global_admin_or_teacher_or_org_admin? || student_owns_enrollment?
  end

  def destroy?
    global_admin_or_teacher_or_org_admin?
  end

  private

  def global_admin_or_teacher_or_org_admin?
    return false unless user

    user.global_admin? ||
      (user.org_admin? && same_organization?) ||
      (user.teacher? && same_organization?)
  end

  def student_owns_enrollment?
    return false unless user&.student?

    record.enrollment.user_id == user.id
  end

  def same_organization?
    record.enrollment.course.organization_id == user.organization_id
  end

  class Scope < Scope
    def resolve
      return scope.none unless user
      return scope.all if user.global_admin?
      return scope.joins(enrollment: :course).where(courses: { organization_id: user.organization_id }) if user.org_admin? || user.teacher?
      return scope.joins(:enrollment).where(enrollments: { user_id: user.id }) if user.student?

      scope.none
    end
  end
end
