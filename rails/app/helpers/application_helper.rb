module ApplicationHelper

  def nav_link_to(title, link, opts={})
    is_active = current_page?(link) ||
      # We redirect home to /sites when user is logged in
      (current_page?(sites_path) && link == root_path)

    icon = opts.delete(:icon)

    content_tag :li, class: 'nav-item' do
      link_to link, opts.merge(class: "flex-column nav-link#{' active' if is_active}") do
        safe_join([bi_icon(icon), title].compact)
      end
    end
  end

  def bi_icon(icon, opts={})
    return unless icon

    opts.reverse_merge!(
      class: ["bi"].append(opts.delete(:class)).compact,
      height: "1.2em",
      width: "1.4em",
      style: "margin-top:-3px;margin-right:4px;#{opts.delete(:style)}")

    content_tag(:svg, opts) do
      content_tag(:use, nil, "xlink:href" =>
        "#{asset_path('bootstrap-icons/bootstrap-icons.svg')}##{icon}")
    end
  end

  def bool_text(bool_val, true_text:'Y', false_text:'N')
    bool_val ? true_text : false_text
  end

  def as_megabytes(bytes)
    number_with_precision(bytes.to_f / 1.megabyte, delimiter: ',', precision: 2)
  end

  def nice_timestamp(timestamp)
    return '-' if timestamp.nil?
    content_tag :span, title: timestamp.to_s do
      "#{time_ago_in_words(timestamp)} ago"
    end
  end

  # For use with overflow: hidden.
  # You can see the full text on hover.
  def span_with_title(text)
    content_tag :span, title: text do
      text
    end
  end

end
