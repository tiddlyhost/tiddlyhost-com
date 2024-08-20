#
# Usage:
#  rails runner scripts/thumbnail_migrate.rb | tee migrate.log
#

# Modify as required
name = 'thumbnail'
service_name = 'amazon'
limit = 500
batch_size = 10
sleep_time = 2

# Avoid buffering when using tee
$stdout.sync = true

count = 0
ActiveStorage::Attachment.
  joins(:blob).
  where(name:, blob: { service_name: }).
  limit(limit).
  find_each(batch_size:) do |attachment|
  puts "#{count += 1}/#{limit}"
  if (site = attachment.record)
    puts "Syncing #{site.name} #{site.class.name} #{site.id}"
    site.sync_thumbnail_storage
  else
    puts "Purging orphan attachment #{attachment.id}"
    attachment.purge
  end
  sleep sleep_time
rescue StandardError => e
  puts "Error: #{e}"
end
