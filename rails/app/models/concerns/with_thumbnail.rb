module WithThumbnail
  extend ActiveSupport::Concern

  included do
    has_one_attached :thumbnail
  end

  def thumbnail_storage_service
    is_private? ? Settings.thumbs_storage_service : Settings.public_thumbs_storage_service
  end

  def thumbnail_with_fallback
    # Note: IIUC the present? method for an active_storage association checks for blob
    # existence, so I don't think we can do `thumbnail && cloned_from&.thumbnail` here
    return thumbnail if thumbnail.present?
    return cloned_from.thumbnail if cloned_from&.thumbnail.present?

    # TODO: If empties had a thumbnail we could use that here too
    nil
  end

  # Todo:
  # - Can we at least set long-ish cache headers?
  # - Do we need to cache to reduce s3 traffic?

  if Rails.env.production?
    DEBOUNCE_WAIT = 2.minutes
  else
    DEBOUNCE_WAIT = 10.seconds
  end

  def update_thumbnail_later
    GenerateThumbnailJob.set(wait: DEBOUNCE_WAIT).perform_later(self.class.name, self.id)
  end

  def thumbnail_fresh?
    thumbnail.present? && thumbnail.blob.created_at > current_content.blob.created_at
  end

  # If the storage service config was changed since the thumbnail was created,
  # this can be used to copy the blob from the old service to the new service.
  # See also scripts/thumbnail_migrate which makes use of this method.
  #
  def sync_thumbnail_storage
    return unless thumbnail.present?
    return if thumbnail.blob.service_name == thumbnail_storage_service

    thumbnail_attach(thumbnail.download)
  end

  # See `find_or_build_blob` in
  #  lib/active_storage/attached/changes/create_one.rb
  #
  def self.attachable_thumbnail_hash(png_content, service_name)
    {
      io: StringIO.new(png_content),
      content_type: 'image/png',
      filename: 'thumb.png',
      service_name:,
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
      sub(/(<script src=")(tiddlywikicore-[\d.]+.js")/, "\\1#{core_url_prefix}/\\2")

    grover = Grover.new(use_html, **grover_opts)

    # For future debugging:
    #Rails.logger.info(grover.send(:normalized_options, path: nil))
    # {"viewport"=>{"width"=>1024, "height"=>680, "deviceScaleFactor"=>0.25},
    #  "requestTimeout"=>30000, "convertTimeout"=>20000, "waitForTimeout"=>5000,
    #  "waitUntil"=>"networkidle2"}

    png = grover.to_png

    thumbnail_attach(png)
  end

  def thumbnail_attach(png)
    old_blob = thumbnail.blob

    # Create a new blob to avoid a "can't modify frozen attributes" error
    attachable_hash = WithThumbnail.attachable_thumbnail_hash(png, thumbnail_storage_service)
    new_blob = ActiveStorage::Blob.create_and_upload!(**attachable_hash)

    # Attach the new blob
    thumbnail.attach(new_blob)

    # If the old blob exists it is now an orphan so make sure to purge it
    old_blob&.purge_later
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
