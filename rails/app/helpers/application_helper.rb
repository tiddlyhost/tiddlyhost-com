module ApplicationHelper

  def nav_link_to(title, link, opts={})
    is_active = current_page?(link) ||
      # We redirect home to /sites when user is logged in
      (current_page?(sites_path) && link == root_path) ||
      # Highlight Hub link for all Hub pages
      (controller_name == 'hub' && link == '/hub')

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

  def gravatar_url(email)
    "https://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email)}"
  end

  def gravatar_image(user, opts={})
    opts[:size] ||= 80
    opts[:class] ||= 'gravatar'
    image_tag(gravatar_url(user.email), opts)
  end

  def bool_text(bool_val, true_text:'Y', false_text:'N')
    bool_val ? true_text : false_text
  end

  def as_megabytes(bytes)
    number_with_precision(bytes.to_f / 1.megabyte, delimiter: ',', precision: 2)
  end

  def datatable_sort_by(order_value, text_value=nil)
    content_tag :td, 'data-order' => order_value.to_i do
      (text_value || order_value).to_s
    end
  end

  def datatable_timestamp(timestamp)
    datatable_sort_by(timestamp.to_i, nice_timestamp(timestamp))
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

  # Same thing but truncate in the dom
  def span_with_title_truncated(full_text, truncate_length=100)
    content_tag :span, title: full_text do
      truncate(full_text, length: truncate_length, separator: ' ')
    end
  end

end
