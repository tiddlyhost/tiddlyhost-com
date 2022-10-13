
module WithThumbnail
  extend ActiveSupport::Concern

  included do
    has_one_attached :thumbnail
  end

  # Todo:
  # - Can we at least set long-ish cache headers?
  # - Do we need to cache to reduce s3 traffic?
  # - Per site or per user throttle or debounce maybe

  # See app/jobs/generate_thumbnail_job
  #
  def update_thumbnail_later
    GenerateThumbnailJob.perform_later(self.class.name, self.id)
  end

  private

  # This is expensive since it spins up a headless chromium
  #
  def update_thumbnail_now
    png = Grover.new(file_download, **grover_opts).to_png
    update(thumbnail: WithThumbnail.attachable_thumbnail_hash(png))
  end

  # See also config/initializers/grover
  #
  def grover_opts
    case tw_kind
    when 'feather'
      {
        style_tag_options: [
          # Hide Feather Wiki "can't save to server" notification
          { content: 'html > body > div.notis { display:none; }' }
        ]
      }

    else
      {}

    end
  end

  # See `find_or_build_blob` in
  #  lib/active_storage/attached/changes/create_one.rb
  #
  def self.attachable_thumbnail_hash(png_content)
    {
      io: StringIO.new(png_content),
      content_type: 'image/png',
      filename: 'thumb.png',
    }
  end

end
