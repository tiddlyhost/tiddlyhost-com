
module SitesHelper

  def site_link(site, opts={})
    link_title = opts.delete(:link_title)
    link_to site.url, {target: '_blank'}.merge(opts) do
      link_title || site.name
    end
  end

  def site_long_link(site, opts={})
    link_to site.url, {target: '_blank'}.merge(opts) do
      (yield if block_given?).to_s + (opts.delete(:name) || site.long_name)
    end
  end

  def site_pretty_link(site, opts={})
    site_long_link(site, opts) do
      image_tag(asset_path(site.favicon_asset_name))
    end
  end

  def site_download_link(site, opts={})
    link_to site.download_url, opts do
      yield
    end
  end

  def site_access(site)
    access_type = if site.redirect_to.present?
      "redirected"
    elsif site.access_hub_listed?
      "hub_listed"
    elsif site.access_public?
      "public"
    else site.access_private?
      "private"
    end

    access_icon(access_type) + access_type.humanize
  end

  def access_icon(access_type, opts={})
    opts = {
      fill: '#6c757d',
      height: '0.95em',
      width: '0.95em',
    }.merge(opts)

    case access_type when "redirected"
      bi_icon('arrow-right-circle', opts)
    when "hub_listed"
      bi_icon('search-heart', opts)
    when "public"
      bi_icon('eye', opts)
    when "private"
      bi_icon('eye-slash', opts)
    end
  end

  def hub_all_url
    add_sort_and_template_params_maybe("/hub")
  end

  def hub_tag_url(tag_name)
    add_sort_and_template_params_maybe("/hub/tag/#{ERB::Util.url_encode(tag_name)}")
  end

  def hub_user_url(username)
    add_sort_and_template_params_maybe("/hub/user/#{ERB::Util.url_encode(username)}")
  end

  # Todo: Could this be replaced by something in SortAndFilterLinkHelper?
  def add_sort_and_template_params_maybe(url)
    sort_and_template_params = params.permit(:s, :t)
    url += "?#{sort_and_template_params.to_query}" if sort_and_template_params.present?
    url
  end

  def logo_for_kind(kind, style='height: 1.4em; margin-top: -3px;')
    image_tag(SiteCommon::KIND_LOGOS[kind], style: style, title: SiteCommon::KINDS[kind])
  end

  def kind_logo(site, style='height: 1.4em; margin-top: -3px; padding-right: 4px;')
    logo_for_kind(site.tw_kind, style) if site.tw_kind
  end

  def kind_summary(site)
    kind_logo(site, 'height: 1.2em; margin-right: 2px; margin-top: -2px;') + " #{site.kind_title} #{site.tw_version}" if site.tw_kind
  end

  def clickable_site_tags(site)
    safe_join(site.tag_list.map do |tag_name|
      link_to tag_name, hub_tag_url(tag_name)
    end, ' ')
  end

end
