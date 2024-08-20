module WithThumbnail
  extend ActiveSupport::Concern

  included do
    has_one_attached :thumbnail, service: Settings.thumbs_storage_service
  end

  # Todo:
  # - Can we at least set long-ish cache headers?
  # - Do we need to cache to reduce s3 traffic?

  DEBOUNCE_WAIT = 2.minutes

  def update_thumbnail_later
    GenerateThumbnailJob.set(wait: DEBOUNCE_WAIT).perform_later(self.class.name, self.id)
  end

  def thumbnail_fresh?
    thumbnail.present? && thumbnail.blob.created_at > current_content.blob.created_at
  end

  # If Settings.thumbs_storage_service changed since the thumbnail was
  # created, this can be used to copy it over to the new storage service
  # See also scripts/thumbnail_migrate
  #
  def sync_thumbnail_storage
    return unless thumbnail.present?
    return if thumbnail.blob.service_name == Settings.thumbs_storage_service

    update(thumbnail: WithThumbnail.attachable_thumbnail_hash(thumbnail.download))
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

  private

  # This is expensive since it spins up a headless chromium
  #
  def update_thumbnail_now
    # So thumbnails work in my local dev environment
    core_url_prefix = Rails.env.development? ? Settings.prod_main_site_url : Settings.main_site_url

    # Similar to inject_external_core_url_prefix but probably uses less memory
    use_html = file_download.
      sub(/(<script src=")(tiddlywikicore-[\d\.]+.js")/, "\\1#{core_url_prefix}/\\2")

    grover = Grover.new(use_html, **grover_opts)

    # For future debugging:
    #Rails.logger.info(grover.send(:normalized_options, path: nil))
    # {"viewport"=>{"width"=>1024, "height"=>680, "deviceScaleFactor"=>0.25},
    #  "requestTimeout"=>30000, "convertTimeout"=>20000, "waitForTimeout"=>5000,
    #  "waitUntil"=>"networkidle2"}

    png = grover.to_png

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
end
