
module SitesHelper

  def site_link(site, opts={})
    link_title = opts.delete(:link_title)
    link_to site.url, {target: '_blank'}.merge(opts) do
      link_title || site.name
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

  def hub_tag_url(tag_name)
    "/hub/tag/#{ERB::Util.url_encode(tag_name)}"
  end

  def hub_user_url(username)
    "/hub/user/#{ERB::Util.url_encode(username)}"
  end

  def clickable_site_tags(site)
    safe_join(site.tag_list.map do |tag_name|
      link_to tag_name, hub_tag_url(tag_name)
    end)
  end

end
