class CoursesController < ApplicationController
  include Authenticatable
  include Pundit::Authorization

  before_action :set_course, only: [ :show, :update, :destroy ]

  def index
    authorize Course
    courses = policy_scope(Course).order(:semester, :year, :month).reverse
    render json: courses
  end

  def show
    render json: @course
  end

  def create
    authorize Course

    incoming_semester = params[:semester].to_sym
    semester_int = Constants::Semesters::SEMESTERS[incoming_semester]

    unless semester_int
      return render json: { error: "Unknown semester '#{incoming_semester}'" }, status: :unprocessable_entity
    end

    @course = Course.new(course_params.merge(
      semester: semester_int,
      user_id: current_user.id,
      organization_id: current_user.organization_id
    ))

    if @course.save
      render json: @course, status: :created
    else
      render json: @course.errors, status: :unprocessable_entity
    end
  end

  def update
    incoming_semester = params[:semester]&.to_sym
    semester_int = Constants::Semesters::SEMESTERS[incoming_semester]

    unless semester_int
      return render json: { error: "Unknown semester '#{semester_key}'" }, status: :unprocessable_entity
    end

    if @course.update(course_params.merge(semester: semester_int))
      render json: @course
    else
      render json: @course.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @course.destroy!
    head :no_content
  end

  private

  def set_course
    @course = Course.find(params[:id])
  end

  def course_params
    params.permit(:name, :course_code, :month, :year, :is_completed)
  end
end
