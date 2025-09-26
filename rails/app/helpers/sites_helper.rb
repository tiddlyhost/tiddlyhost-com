module SitesHelper
  def site_link(site, opts = {})
    link_title = opts.delete(:link_title)
    link_to site.url, { target: '_blank' }.merge(opts) do
      link_title || site.name
    end
  end

  def site_long_link(site, opts = {})
    link_to site.url, { target: '_blank' }.merge(opts) do
      (yield if block_given?).to_s + (opts.delete(:name) || site.long_name)
    end
  end

  def site_pretty_link(site, opts = {})
    site_long_link(site, opts) do
      image_tag(asset_path(site.favicon_asset_name))
    end
  end

  def site_download_link(site, opts = {}, &)
    link_to(site.download_url, opts, &)
  end

  def thumbnail_url(thumbnail)
    # TODO: The blob.url doesn't work in a local dev environment
    # with disk based active storage, hence this production test.
    # Maybe this can be fixed..?
    return rails_storage_proxy_path(thumbnail) unless Rails.env.production?

    if thumbnail.record.is_private?
      # TODO: Could/should we use the one-time blob url here with the
      # credentials in the X-Amz params? Or, should we use the url_for
      # redirect urls..?
      rails_storage_proxy_path(thumbnail)
    else
      # Public sites can have public thumbnails
      # TODO: Could/should we use url_for redirect urls here also..?
      thumbnail.blob.url
    end
  end

  def site_access(site)
    # rubocop: disable Layout/IndentationWidth
    access_type = if site.redirect_to.present?
      'redirected'
    elsif site.access_hub_listed?
      'hub_listed'
    elsif site.access_public?
      'public'
    elsif site.access_private?
      'private'
    end

    # We don't call it "Hub listed" any more
    access_title = if access_type == 'hub_listed'
      'Searchable'
    else
      access_type.humanize
    end
    # rubocop: enable Layout/IndentationWidth

    access_icon(access_type) + access_title
  end

  # Used when displaying save history to show if two saved versions
  # are identical, since I don't want to expose the real blob checksum.
  def cosmetic_saved_version_checksum(attachment)
    content_tag :span, class: ['font-monospace', 'th-text-90'] do
      short_checksum(attachment.blob.checksum)
    end
  end

  def short_checksum(str)
    Digest::SHA2.hexdigest(str)[0..6]
  end

  def access_icon(access_type, opts = {})
    opts = {
      fill: '#6c757d',
      height: '0.95em',
      width: '0.95em',
    }.merge(opts)

    case access_type
    when 'redirected'
      bi_icon('arrow-right-circle', opts)
    when 'hub_listed', 'hub'
      bi_icon('search-heart', opts)
    when 'public'
      bi_icon('eye', opts)
    when 'private'
      bi_icon('eye-slash', opts)
    end
  end

  def hub_all_url
    add_sort_and_template_params_maybe('/explore')
  end

  def hub_tag_url(tag_name)
    add_sort_and_template_params_maybe("/explore/tag/#{ERB::Util.url_encode(tag_name)}")
  end

  def hub_user_url(username)
    add_sort_and_template_params_maybe("/explore/user/#{ERB::Util.url_encode(username)}")
  end

  # Todo: Could this be replaced by something in SortAndFilterLinkHelper?
  def add_sort_and_template_params_maybe(url)
    sort_and_template_params = params.slice(:s, :t).to_unsafe_h
    url += "?#{sort_and_template_params.to_query}" if sort_and_template_params.present?
    url
  end

  def logo_for_kind(kind, style = 'height: 1.4em; margin-top: -3px;')
    image_tag(SiteCommon::KIND_LOGOS[kind.to_s], style:, title: SiteCommon::KINDS[kind.to_s]) if SiteCommon::KIND_LOGOS[kind.to_s].present?
  end

  def kind_logo(site, style = 'height: 1.4em; margin-top: -3px; padding-right: 4px;')
    logo_for_kind(site.tw_kind, style) if site.tw_kind
  end

  def kind_summary(site)
    kind_logo(site, 'height: 1.2em; margin-right: 2px; margin-top: -2px;') + " #{site.kind_title} #{site.tw_version}" if site.tw_kind
  end

  def hub_tag_links(site, crawler_protect: false)
    safe_join(site.tag_list.map do |tag_name|
      if crawler_protect
        # Convert to actual URL string for the data attribute
        url_string = url_for(hub_tag_url(tag_name))
        link_to tag_name, '#', rel: 'nofollow', 'data-crawler-protect-href': url_string
      else
        link_to tag_name, hub_tag_url(tag_name), rel: 'nofollow'
      end
    end, ' ')
  end

  def home_tag_links(site)
    safe_join(site.tag_list.map do |tag_name|
      # Use filter_link_url to get the URL but create our own link without dropdown-item classes
      url = filter_link_url(:tags, tag_name)
      link_to tag_name, url, rel: 'nofollow'
    end, ' ')
  end

  def show_history_link?(site)
    # Skip the link if the site hasn't been saved yet
    return false unless site.save_count > 0

    feature_enabled?(:site_history) || feature_enabled?(:site_history_preview)
  end

  # It's an edge case, but when user has more saved sites than the keep
  # count make them appear to be fading away. They will be hard removed
  # as soon as the site next prunes it's files.
  #
  def fade_away_opacity(site, index)
    how_far_under = index - site.keep_count
    opac = 100 - (23 * (how_far_under + 3))
    "opacity: #{opac.clamp(0, 100)}%;"
  end
end
