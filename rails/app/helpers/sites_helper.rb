
module SitesHelper

  def site_link(site, opts={})
    link_to site.name, site.url, {target: '_blank'}.merge(opts)
  end

  def site_long_link(site, opts={})
    link_to URI(site.url).hostname, site.url, {target: '_blank'}.merge(opts)
  end
end
