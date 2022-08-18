#
# Usage:
#  rails runner fixup-scripts/hub-screenshots.rb
#
# To make the hub look pretty, try to generate screenshots
# for every hub-listed site.
#
do_it = ->(site) do
  if site.thumbnail.present?
    puts "Thumbnail exists for site #{site.name}"
  elsif site.raw_byte_size && site.raw_byte_size > 50_000_000
    # Seems to get crashy if the site is too big. :|
    puts "Skipping too big site #{site.name}"
  else
    puts "Creating thumbnail for #{site.name}"
    site.send(:update_thumbnail_now)
  end
rescue => e
  puts "Error: #{e}"
end

Site.searchable.find_each(&do_it)
TspotSite.searchable.find_each(&do_it)
