# frozen_string_literal: true

module HubHelper
  def hub_link_to(title, link, opts={})
    tab_link_to(title, link, opts)
  end

  def hub_tag_link_to(tag_name)
    hub_link_to(bi_icon(:tag) + tag_name, hub_tag_url(tag_name))
  end

  # Fixme: Use rails' helper number_to_human
  def nice_view_count(view_count)
    if view_count < 1_000
      view_count.to_s

    elsif view_count < 1_000_000
      precision = view_count > 10_000 ? 0 : 1
      "#{number_with_precision(view_count.to_f/1_000, precision: precision)}K"

    else
      precision = view_count > 10_000_000 ? 0 : 1
      "#{number_with_precision(view_count.to_f/1_000_000, precision: precision)}M"

    end
  end

  def views_and_updated_text(hub_site)
    [
      "#{nice_view_count(hub_site.view_count)} views",
      ("#{brief_time_ago_in_words(hub_site.blob_created_at)}" if hub_site.blob_created_at && hub_site.save_count > 0)
    ].compact.join(", ")
  end
end
