class AssessmentSerializer < ActiveModel::Serializer
  attributes :id, :updated_at, :assessed_on, :score, :files

  def files
    object.files.map do |file|
      {
        filename: file.filename.to_s,
        content_type: file.content_type,
        byte_size: file.byte_size,
        url: rails_blob_url(file, only_path: true)
      }
    end
  end
end
