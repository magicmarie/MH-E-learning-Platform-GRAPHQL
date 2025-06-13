class ResourceSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :title, :description, :visible, :course_name, :file,
              :created_at, :created_by

  def course_name
    object.course&.name
  end

  def created_by
    object.course.user&.email
  end

  def file
    return nil unless object.file.attached?

    {
      filename: object.file.filename.to_s,
      content_type: object.file.content_type,
      byte_size: object.file.byte_size,
      url: rails_blob_url(object.file, host: "http://localhost:3000")
    }
  end
end
