module HubHelper

  def hub_link_to(title, link, opts={})
    tab_link_to(title, link, opts)
  end

  def hub_tag_link_to(tag_name)
    hub_link_to(bi_icon(:tag) + tag_name, hub_tag_url(tag_name))
  end

end
