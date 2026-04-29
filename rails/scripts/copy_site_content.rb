#
# Usage:
#  rails runner scripts/copy_site_content.rb
#
# Copies the content from one site to another.
# Modify from_site_name and to_site_name below as needed.
#

puts "*****************************************************************"
puts "* Use with caution. For careful adhoc recovery operations only. *"
puts "* Destructive to the content of to_site content.                *"
puts "*****************************************************************"

# Set carefully as required
from_site_class = Site
#to_site_class = TspotSite
from_site_name = '__set_carefully__'

#to_site_class = Site
to_site_class = TspotSite
to_site_name = '__as_required__'

from_site = from_site_class.find_by(name: from_site_name)
if from_site
  puts "Will copy from:\n\n"
  puts from_site
  puts "\n\n"
else
  puts "Error: Source #{from_site_class} '#{from_site_name}' not found"
  exit 1
end

to_site = to_site_class.find_by(name: to_site_name)
if to_site
  puts "Will copy to:\n\n"
  puts to_site
  puts "\n\n"
else
  puts "Error: Destination #{to_site_class} '#{to_site_name}' not found"
  exit 1
end

if ENV['REALLY_DO_IT'] != 'yes'
  puts "Dry run mode. Set REALLY_DO_IT=yes to actually copy."
  exit 0
end

backup_file = "#{to_site_name}-backup-#{Time.now.strftime('%Y%m%d-%H%M%S')}.html"
puts "Backing up '#{to_site_name}' to #{backup_file}..."
File.write(backup_file, to_site.file_download)
puts "Backup saved."

puts "Copying content from '#{from_site_name}' to '#{to_site_name}'..."

if to_site.content_upload(from_site.file_download)
  puts "Done!"
else
  puts "Error: Upload failed"
  exit 1
end
