module ApplicationHelper

  def nav_link_to(title, link, opts={})
    is_active = current_page?(link) ||
      # We redirect home to /sites when user is logged in
      (current_page?(sites_path) && link == root_path) ||
      # Highlight Hub link for all Hub pages
      (controller_name == 'hub' && link == '/hub') ||
      # Highlight Admin link for all Admin pages
      (controller_name == 'admin' && link == '/admin')

    icon = opts.delete(:icon)

    content_tag :li, class: 'nav-item' do
      link_to link, opts.merge(class: "flex-column nav-link#{' active' if is_active}") do
        safe_join([bi_icon(icon), title].compact)
      end
    end
  end

  def tab_link_to(title, link, opts={})
    is_active = current_page?(link)
    content_tag :li, class: 'nav-item' do
      link_to link, opts.merge(class: "nav-link#{' active' if is_active}") do
        title
      end
    end
  end

  def bi_icon(icon, opts={})
    return unless icon

    opts.reverse_merge!(
      class: ["bi"].append(opts.delete(:class)).compact,
      height: "1.2em",
      width: "1.4em",
      style: "margin-top:-3px;margin-right:3px;#{opts.delete(:style)}")

    content_tag(:svg, opts) do
      content_tag(:use, nil, "xlink:href" =>
        "#{asset_path('bootstrap-icons/bootstrap-icons.svg')}##{icon}")
    end
  end

  def display_none_when(condition)
    "display: #{ condition ? 'none' : 'block' };"
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

  def as_megabytes(bytes, precision: 2)
    number_with_precision(bytes.to_f / 1.megabyte, delimiter: ',', precision: precision)
  end

  def datatable_sort_by(sort_by_int, text_value=nil)
    content_tag :td, 'data-order' => sort_by_int.to_i do
      (text_value || sort_by_int).to_s
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

  def nice_percentage(number, total, opts={})
     number_to_percentage(100 * number / total, opts.reverse_merge(precision: 1))
  end

  def support_mail_to(opts={})
    mail_to(Settings.support_email,
      opts.delete(:link_title) || Settings.support_email_name,
      opts.reverse_merge(target: '_blank'))
  end

  def github_history_url(branch_or_sha)
    "#{Settings.github_url}/commits/#{branch_or_sha}"
  end

  def github_history_link_to(title, sha, opts={})
    link_to(title, github_history_url(sha), {target: '_blank'}.reverse_merge(opts))
  end

end
