module HubHelper

  def hub_link_to(title, link, opts={})
    tab_link_to(title, link, opts)
  end

  def hub_tag_link_to(tag_name)
    hub_link_to(bi_icon(:tag) + tag_name, tag_url(tag_name))
  end

  def sort_url(new_sort)
    params.permit(:sort, :search).merge(sort: new_sort)
  end

  def clear_search_url
    params.permit(:sort, :search).merge(search: nil)
  end

end
