
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

  def card_color(title, value)
    case title.downcase
    when /users/, /active/
      '#ffe'
    when /tspots/
      '#efe'
    when /dupe/
      '#ffeee8' if value > 0
    when /sites/
      '#eef8ff'
    else
      'var(--bs-gray-100)'
    end
  end

end
