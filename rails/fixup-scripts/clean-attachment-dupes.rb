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

sites_with_dupes =
  ActiveStorage::Attachment.group(:record_type, :record_id).count.
    map{ |type_and_id, count| type_and_id if count > 1}.compact.
    map{ |record_type, record_id| self.class.const_get(record_type).find(record_id) }

sites_with_dupes.each do |s|
  puts "#{s.class.name} #{s.id} #{s.name}"

  # Sort the attachments so the most recently created one is first
  attachments = ActiveStorage::Attachment.where(record_type: s.class.name, record_id: s.id).
    to_a.sort_by{ |a| a.blob.created_at }.reverse

  # Keep the most recent one since it's presumably the latest save
  attachments[0..0].each do |a|
    puts " - KEEP #{a.id} #{a.blob.key} #{a.blob.created_at}"
  end

  # Delete the others (maybe)
  attachments[1..].each do |a|
    puts " - DUPE #{a.id} #{a.blob.key} #{a.blob.created_at}"

    # Do it..
    a.destroy if ENV['REALLY'] == '1'
  end

  puts "\n"
end
