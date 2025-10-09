#
# Usage:
#  rails runner scripts/recover_missing_blobs.rb
#
# Note: Some of the code here was recreated/copied into methods
# defined in app/models/concerns/with_saved_content.rb. Since this
# is mostly a "one-time" script for a specific incident, I decided
# to keep it as it is. If I'm doing somethig like this in future I'll
# make a new version and use the newer methods.
#

problem_sites = Site.where("updated_at > ?", 1.week.ago).select do |s|
  # Newest blob key is missing from the storage bucket
  !s.blob.service.exist?(s.blob.key) &&
  # Has more than one blob
  s.saved_version_count > 1
end

def render_email(site, blob)
  %(
Hi #{site.user.username_or_name},

There was a Tiddlyhost outage on Sunday caused by a hosting provider incident. See https://status.linode.com/incidents/6yw88b0ft94g for details about the incident.

It caused some Tiddlyhost saves to fail, and for some sites it resulted in a persistent "500 Internal Server" problem.

Your site "#{site.name}" is one of the sites impacted.

To get the site working again I've restored it to an older saved version with timestamp "#{blob.created_at}", but unfortunately any later updates from July 27 are unable to be recovered.

In summary, https://#{site.name}.tiddlyhost.com/ has been recovered, but changes from July 27 have been lost.

Apologies,

Simon.
).strip
end

def send_notification_email(site, blob)
  ActionMailer::Base.mail(
    from: Settings.support_email,
    to: Settings.support_email,
    # Uncomment to send for real
    # to: site.user.email,
    bcc: Settings.support_email,
    reply_to: Settings.support_email,
    subject: "Recovering Tiddlyhost site '#{site.name}'",
    body: render_email(site, blob)
  ).deliver_now
end

def recover_site(site, from_blob)
  site.content_upload(site.file_download(from_blob.id))
end

problem_sites.each do |site|
  puts "============================================================"
  puts "#{site.id} #{site.name}"

  best_blob = nil
  site.saved_content_files.order('created_at DESC').map(&:blob).each do |b|
    # The newest blob that exists
    best_blob = b if !best_blob && b.service.exist?(b.key)
    # So we can confirm it looks right
    puts "#{b.created_at} #{b.key} #{b.service.exist?(b.key)}"
  end
  puts "Will recover from blob #{best_blob.key}"

  # Uncomment to really do it
  # recover_site(site, best_blob)
  # send_notification_email(site, best_blob)
end
