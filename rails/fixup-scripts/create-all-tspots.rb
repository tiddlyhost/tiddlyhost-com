#
# Usage:
#  cat name-list.txt | rails runner fixup-scripts/create-all-tspots.rb
#
ARGF.each_line do |site_name|
  site_name.strip!

  if TspotSite.find_by_name(site_name).present?
    puts "#{site_name} skipped"

  else
    # Create stub site
    TspotSite.create(name: site_name)
    puts "#{site_name} created"

  end

end
