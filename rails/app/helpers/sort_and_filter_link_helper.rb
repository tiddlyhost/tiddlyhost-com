#
# This is included in ApplicationController so these
# methods can be used in controllers as well as views
#
module SortAndFilterLinkHelper
  def filter_results(unfiltered_results)
    filtered_results = unfiltered_results

    filter_params.each do |param_key, param_opts|
      if param_opts[:filter]
        # E.g. for a search query. Assume the value is param value is passed in to the filter
        filtered_results = param_opts[:filter].call(filtered_results, params[param_key]) if params[param_key].present?

      else
        # Assume there's a list of expected values for the param, each with its own filter
        param_opts.each do |param_val, filter_opts|
          if params[param_key] == param_val.to_s
            filtered_results = filter_opts[:filter].call(filtered_results)
          end
        end

      end
    end

    filtered_results
  end

  #
  # Used in the sites list and the admin pages
  # This provides asc/desc flipping
  #
  # Todo: link title could be found in sort_options[_][:title]
  # if we pass in the param_val
  def sort_link(link_title, default_sort_dir = :desc, extra_klass = nil)
    # Derive the param value from the title
    param_val = link_title.downcase.gsub(/[^a-z]/, '')

    if sort_by == param_val
      # We're already sorting by this field, so provide a toggle direction link
      new_sort_by = flipped_sort_by
      klass = sort_css_class
    else
      # Clicking will select a new sort value
      new_sort_by = sort_val_with_suffix(param_val, sort_desc: default_sort_dir == :desc)
      klass = nil
    end

    link_to(sort_link_url(new_sort_by), class: [klass, extra_klass].compact, rel: 'nofollow') do
      link_title
    end
  end

  #
  # Used in the hub
  # This one does not provide the asc/desc flipping
  #
  def simple_sort_link(new_sort_by, klass = 'dropdown-item', crawler_protect: false)
    sel = 'sel' if sort_by == new_sort_by&.to_s
    url = sort_link_url(new_sort_by)

    if crawler_protect
      # Convert hash to actual URL string for the data attribute
      url_string = url_for(url)
      link_to('#', class: [klass, sel], rel: 'nofollow', 'data-crawler-protect-href': url_string) do
        sort_options[new_sort_by][:title]
      end
    else
      link_to(sort_options[new_sort_by][:title], url, class: [klass, sel], rel: 'nofollow')
    end
  end

  def filter_link_group(param_key, &)
    links = [
      filter_link(param_key, nil, &),
      filter_params[param_key].keys.map { |v| filter_link(param_key, v, &) }
    ]
    safe_join(links.flatten)
  end

  def clear_search_url
    filter_link_url(:q, nil)
  end

  def filter_link(param_key, param_val, crawler_protect: false)
    filter_opts = filter_params.dig(param_key&.to_sym, param_val&.to_sym) || {}
    link_title = filter_opts[:title] || param_val&.to_s || 'show all'

    selected = params[param_key] == param_val&.to_s
    klass = ['dropdown-item', (selected ? 'sel' : 'notsel')]
    url = filter_link_url(param_key, param_val)

    if crawler_protect
      # Convert hash to actual URL string for the data attribute
      url_string = url_for(url)
      link_to('#', class: klass, rel: 'nofollow', 'data-crawler-protect-href': url_string) do
        if block_given?
          yield param_val, link_title
        else
          link_title
        end
      end
    else
      link_to(url, class: klass, rel: 'nofollow') do
        if block_given?
          yield param_val, link_title
        else
          link_title
        end
      end
    end
  end

  # A radio button that acts like a link
  def filter_radio_link(link_title, param_key, param_val = nil)
    param_val = param_val.to_s.presence
    selected = params[param_key] == param_val
    onclick = "window.location.href = '#{url_for(filter_link_url(param_key, param_val))}'"
    content_tag :label do
      "#{radio_button_tag(param_key, param_val, selected, onclick:)} #{link_title}".html_safe
    end
  end

  def filter_link_url(param_key, param_val)
    sort_filter_url(param_key, param_val)
  end

  def sort_link_url(param_val)
    param_val = nil if param_val.to_s == default_sort_by
    sort_filter_url(SORT_PARAM, param_val)
  end

  # Preserve the sort and filter options when searching
  # (For search forms)
  #
  def hidden_sort_filter_fields
    safe_join(sort_filter_param_keys.map do |k|
      hidden_field_tag(k, params[k]) if params[k].present? && k != SEARCH_PARAM
    end.compact)
  end

  private

  #--------------------------------------------------------
  # For sql sorting
  # Used in the admin controller and the sites controller
  #
  def sort_sql
    null_always_last = sort_null_always_last_vals.include?(sort_by)
    asc_desc_sql = sort_desc? ? 'DESC NULLS LAST' : "ASC NULLS #{null_always_last ? 'LAST' : 'FIRST'}"
    Array.wrap(sort_opt).map { |expr| "#{expr} #{asc_desc_sql}" }.join(',')
  end

  #--------------------------------------------------------
  # For links
  #
  def flipped_sort_by(sort_val = sort_by)
    sort_val_with_suffix(sort_val, sort_desc: !sort_desc?)
  end

  def sort_val_with_suffix(sort_val, sort_desc: false)
    "#{sort_val}#{DESC_SUFFIX if sort_desc}"
  end

  def sort_css_class
    sort_desc? ? 'desc' : 'asc'
  end

  def sort_bi_icon
    sort_desc? ? 'sort-up' : 'sort-down'
  end

  #--------------------------------------------------------
  # For url preparation
  #
  # Add the new param but preserve existing params
  # Can be stringified with url_for
  def sort_filter_url(param_key, param_val)
    params.slice(*sort_filter_param_keys).to_unsafe_h.merge(param_key => param_val.to_s.presence)
  end

  def sort_filter_param_keys
    [SORT_PARAM] + filter_params.keys
  end

  #--------------------------------------------------------
  # Parameter handling for sorting
  #
  SORT_PARAM = :s
  SEARCH_PARAM = :q
  DESC_SUFFIX = '_desc'

  def sort_opt
    sort_options[sort_by.to_sym] || sort_options[default_sort_by.to_sym]
  end

  def sort_by
    sort_by_raw.delete_suffix(DESC_SUFFIX)
  end

  def sort_desc?
    sort_by_raw.end_with?(DESC_SUFFIX)
  end

  def sort_by_raw
    params[SORT_PARAM].presence || default_sort_by
  end

  def search_text
    params[SEARCH_PARAM].presence
  end

  #--------------------------------------------------------
  # Stuff defined in the controller
  #
  def default_sort_by
    c = get_controller
    if c.respond_to?(:default_sort, true)
      c.send(:default_sort).to_s
    else
      c.class::DEFAULT_SORT.to_s
    end
  end

  def filter_params
    get_controller.class::FILTER_PARAMS
  end

  def sort_options
    get_controller.class::SORT_OPTIONS
  end

  def sort_null_always_last_vals
    get_controller.class::NULL_ALWAYS_LAST
  end

  # Allow these helper methods to be usable in controllers as well
  def get_controller
    is_a?(ApplicationController) ? self : controller
  end
end
