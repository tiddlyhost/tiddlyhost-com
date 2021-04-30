
module AdminHelper

  def link_to_user_sites(text, user, opts={})
    link_to(text, { controller: :admin,
      action: opts.delete(:action) || action_name,
      user: user.id }, opts)
  end

  def link_to_user_sites_with_count(user, sites_type)
    link_to_user_sites(pluralize(user.send(sites_type).count,
      sites_type.to_s.singularize.titleize.downcase), user, action: sites_type)
  end

  def link_to_user_hub_with_count(user)
    return unless user.has_username?
    link_to(hub_user_url(user.username), target: '_blank') do
      safe_join([pluralize(user.hub_sites_count, 'hub site'),
      bi_icon('arrow-right-short')])
    end
  end

  def link_to_user(text, user, opts={})
    link_to(text||'', { controller: :admin, action: :users, user: user.id }, opts)
  end

  def pagination_info(records)
    last_item_index = records.next_page.present? ?
      records.offset + records.per_page :
      records.total_entries

    "Showing #{records.offset + 1} to #{last_item_index} of #{records.total_entries} entries."
  end

  def admin_site_link(site)
    if site.is_private?
      "#{site.name} #{site_link(site, link_title: '▪')}".html_safe
    else
      site_link(site)
    end
  end

  def sort_link(link_title, default_dir=:desc)
    field = link_title.downcase.gsub(/[^a-z]/, '')
    if @sort_by == field
      new_sort_by = "#{field}#{'_desc' unless @is_desc}"
      klass = @is_desc ? 'desc' : 'asc'
    else
      new_sort_by = "#{field}#{'_desc' unless default_dir == :asc}"
      klass = nil
    end

    link_to(params.permit(AdminController::FILTER_PARAMS).merge(s: new_sort_by), class: klass) do
      link_title
    end
  end

  # A radio button that acts like a link
  def filter_radio_link(title, key, value=nil)
    url = params.permit(AdminController::FILTER_PARAMS)
    url.merge!(key => value)
    content_tag :label do
      radio_button_tag(key, value, params[key] == value, onclick:
        "window.location.href = '#{url_for(url)}'") + ' ' + title
    end
  end

  def card_color(title)
    case title.downcase
    when /users/, /active/
      '#ffe'
    when /tspots/
      '#efe'
    when /dupe/
      '#fff6f2'
    when /sites/
      '#eef8ff'
    end
  end

end
