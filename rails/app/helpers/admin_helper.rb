
module AdminHelper

  def link_to_user_sites(text, user, opts={})
    link_to(text, { controller: :admin,
      action: opts.delete(:action) || action_name,
      user_id: user.id }, opts)
  end

  def link_to_user_sites_with_count(user, sites_type)
    link_to_user_sites(pluralize(user.send(sites_type).count,
      sites_type.to_s.singularize.titleize.downcase), user, action: sites_type)
  end

  def link_to_user(text, user, opts={})
    link_to(text, { controller: :admin, action: :users, user_id: user.id }, opts)
  end

  def pagination_info(records)
    last_item_index = records.next_page.present? ?
      records.offset + records.per_page :
      records.total_entries

    "Showing #{records.offset + 1} to #{last_item_index} of #{records.total_entries} entries."
  end

  def admin_site_link(site)
    if !site.exists?
      "#{site.name} #{site_link(site, link_title: '○')}".html_safe
    elsif site.is_private?
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
      new_sort_by = "#{field}_#{default_dir}"
      klass = nil
    end

    link_to(params.permit(:controller, :action, :user_id).merge(sort_by: new_sort_by), class: klass) do
      link_title
    end
  end

  def card_color(title)
    case title.downcase
    when /users/
      '#ffe'
    when /tspots/
      '#efe'
    when /sites/
      '#eef8ff'
    end
  end

end
