#
# Usage:
#  rails runner scripts/add_custom_domain.rb
#
# This script manually adds a custom domain to a site.
# Modify the site_name and domain variables below as needed.
#
# Later we'll add some UI for this, but for now I want to be
# able to experiment little by little.
#

# Modify these variables as needed
site_name = 'randomibis'
domain = 'randomibis.com'

# Find the site
site = Site.find_by(name: site_name)
unless site
  puts "Error: Site '#{site_name}' not found"
  exit 1
end

# Check if site already has a custom domain
if site.custom_domain
  puts "Error: Site '#{site_name}' already has a custom domain: #{site.custom_domain.domain}"
  exit 1
end

# Create the custom domain
custom_domain = CustomDomain.new(
  site: site,
  domain: domain
)

if custom_domain.save
  puts "Success! Custom domain added to site '#{site_name}'"
  puts
  puts "Domain: #{custom_domain.domain}"
  puts "Status: #{custom_domain.status}"
  puts "SSL Status: #{custom_domain.ssl_status}"
  puts
  puts "=" * 70
  puts custom_domain.dns_verification_instructions
  puts "=" * 70
  puts
  puts "To verify the domain, you can run:"
  puts "  custom_domain = CustomDomain.find(#{custom_domain.id})"
  puts "  # ... then implement verification logic when ready"
else
  puts "Error: Failed to create custom domain"
  puts custom_domain.errors.full_messages.join("\n")
  exit 1
end
