#
# Sometimes the old attachment doesn't get removed when a new one is
# created. I think it happens during a service restart, but I'm not
# certain. This cleans up the left over duplicate attachments.
#
# Usage:
#  # Show a list
#  rails runner fixup-scripts/clean-attachment-dupes.rb
#
#  # Really delete them
#  REALLY=1 rails runner fixup-scripts/clean-attachment-dupes.rb
#
#

attachment_name = if ENV['THUMB'] == '1'
  # Thumbnail image
  'thumbnail'
else
  # Uploaded TiddlyWiki file
  'tiddlywiki_file'
end

attachment_info = ->(a) { "#{a.name} #{a.id} #{a.created_at} blob #{a.blob.id} #{a.blob.key} #{a.blob.created_at}" }

sites_with_dupes =
  ActiveStorage::Attachment.unscoped.where(name: attachment_name).
    group(:record_type, :record_id).count.
    map{ |type_and_id, count| type_and_id if count > 1}.compact.
    map{ |record_type, record_id| self.class.const_get(record_type).find_by_id(record_id) }.compact

if sites_with_dupes.empty?
  puts "No dupes found."

else
  sites_with_dupes.each do |s|
    # Show the blob key so you can sanity check that the right one is going to be kept
    puts "#{s.class.name} #{s.id} #{s.name} #{s.blob.key}"

    # Because of the default scope added to ActiveStorage::Attachment this should be sorted newest first already
    attachments = ActiveStorage::Attachment.where(name: attachment_name, record_type: s.class.name, record_id: s.id).to_a

    # Keep the most recent one since it's presumably the latest save
    attachments[0..0].each do |a|
      puts " - KEEP #{attachment_info.call(a)}"
    end

    # Delete the others (maybe)
    attachments[1..].each do |a|
      puts " - DUPE #{attachment_info.call(a)}"

      # Do it..
      a.destroy if ENV['REALLY'] == '1'
    end

    puts "\n"
  end
end
