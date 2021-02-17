
module SitesHelper

  def site_link(site, opts={})
    link_to site.name, site.url, {target: '_blank'}.merge(opts)
  end

  def site_long_link(site, opts={})
    link_to URI(site.url).hostname, site.url, {target: '_blank'}.merge(opts)
  end

  def site_access(site)
    [
      site.is_public? ? 'Public' : 'Private',
      site.is_public? && site.is_searchable? ? 'Searchable' : nil

    ].compact.join(', ')
  end

  def site_tags(site)
    safe_join(site.tag_list.map do |tag_name|
      content_tag :span do
        tag_name
      end
    end)
  end

end
