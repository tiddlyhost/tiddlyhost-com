
module SitesHelper

  def site_link(site, opts={})
    link_to site.url, {target: '_blank'}.merge(opts) do
      site.name
    end
  end

  def site_long_link(site, opts={})
    link_to site.url, {target: '_blank'}.merge(opts) do
      URI(site.url).hostname
    end
  end

  def site_download_link(site, opts={})
    link_to site.download_url, opts do
      yield
    end
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

  def tag_url(tag_name)
    "/hub/tag/#{tag_name}"
  end

  def clickable_site_tags(site)
    safe_join(site.tag_list.map do |tag_name|
      link_to tag_name, tag_url(tag_name)
    end)
  end

end
