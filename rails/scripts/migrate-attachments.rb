#
# Usage:
#  rails runner scripts/migrate-attachments.rb
#
#[TspotSite].each do |klass|
#[Site].each do |klass|
[Site, TspotSite].each do |klass|

  klass.with_tiddlywiki_file.limit(2000).order(:id).each do |site|

    print "#{site.name}/#{klass.name}/#{site.id}... "

    original_site_timestamp = site.updated_at
    original_blob_timestamp = site.blob_created_at

    site_content = site.uncached_file_download rescue nil
    unless site_content
      puts "Skipping broken site!"
      next
    end

    site.update(WithSavedContent.attachment_params(site_content))
    site.prune_attachments_now

    site.reload

    # Decided not to do this after all
    #site.send(:update_thumbnail_now) if !site.thumbnail.present? && site.user.present?

    site.update_column(:updated_at, original_site_timestamp)
    site.blob.update_column(:created_at, original_blob_timestamp)

    # Sanity checks
    raise "Unexpected tiddlywiki_file found!" if site.reload.tiddlywiki_file.attached?
    raise "Expected saved_content_file not found!" if !site.reload.saved_content_files.attached?
    raise "More than one found!" if site.reload.saved_version_count > 1
    raise "Blob timestsamp wrong!" if site.reload.blob.created_at != original_blob_timestamp
    raise "Site timestamp wrong!" if site.reload.updated_at != original_site_timestamp

    puts "Done"
  end
end
