class Image < ApplicationRecord
  attr_accessor :exif
  attr_accessor :liked

  belongs_to :user
  has_many :likes, -> { where status: Like::STATUS_LIKE }

  validates :title, length: {minimum: 2}, presence: true
  has_attached_file :img_file, styles: { thumbnail: "640x640#" }
  validates_attachment :img_file,
    content_type: { content_type: ["image/jpeg", "image/gif", "image/png"] } if Rails.application.config.validates_paperclip_attachment
  do_not_validate_attachment_file_type unless Rails.application.config.validates_paperclip_attachment
  validate :url_or_file_presence

  default_scope do
    order(created_at: :desc)
  end

  def url_or_file_presence
    if url.blank? && img_file.blank?
      errors.add(:url, "can't be presense")
    end
  end

  def img_url(style = :thumbnail)
    url.blank? ? img_file(style) : url
  end
end
