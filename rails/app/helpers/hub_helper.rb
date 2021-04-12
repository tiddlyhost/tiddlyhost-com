module HubHelper

  def hub_link_to(title, link, opts={})
    tab_link_to(title, link, opts)
  end

  def hub_tag_link_to(tag_name)
    hub_link_to(bi_icon(:tag) + tag_name, hub_tag_url(tag_name))
  end

  def views_and_updated_text(hub_site)
    [
      "#{hub_site.view_count} views",
      ("updated #{brief_time_ago_in_words(hub_site.blob_created_at)}" if hub_site.blob_created_at)

    ].compact.join(", ")
  end

end
