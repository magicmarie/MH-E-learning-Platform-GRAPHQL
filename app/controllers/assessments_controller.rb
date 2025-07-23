# frozen_string_literal: true

class AssessmentsController < ApplicationController
  before_action :set_assessment, only: [ :show, :update ]
  before_action :authorize_assessment

  def index
    @assessments = policy_scope(Assessment)
    render json: @assessments
  end

  def show
    render json: @assessment
  end

  def update
    if current_user.teacher? || current_user.org_admin?
      @assessment.assessed_on = Time.current
    elsif current_user.student?
      @assessment.submitted_at = Time.current
    end

    if @assessment.update(assessment_params)
      user_email = @assessment.enrollment.user.email

      begin
        AssessmentMailer.welcome_user(@assessment, user_email).deliver_now
      rescue => e
        Rails.logger.error("Failed to send assessment email to #{user.email}: #{e.message}")
      end

      render json: @assessment
    else
      render json: { errors: @assessment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_assessment
    @assessment = Assessment.find(params[:id])
  end

  def authorize_assessment
    authorize @assessment
  end

  def assessment_params
    if current_user.student?
      params.require(:assessment).permit(:score, :submitted_at, files: [])
    else
      params.require(:assessment).permit(:score, :enrollment_id, :assignment_id)
    end
  end
end
