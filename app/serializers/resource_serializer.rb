class ResourceSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :title, :description, :visible, :course_name, :file,
              :created_at, :created_by

  def course_name
    object.course&.name
  end

  def created_by
    object.user&.email
  end
end
