module ApplicationHelper
  include Recaptcha::Adapters::ViewMethods

  def nice_byte_count(bytes, precision: 3)
    return '-' if bytes.nil?

    number_to_human_size(bytes, precision:).delete_suffix(' Bytes')
  end

  def nice_byte_count_nbsp(bytes)
    nice_byte_count(bytes).gsub(' ', '&nbsp;').html_safe
  end

  VIEW_COUNT_UNITS = { unit: '', thousand: 'K', million: 'M', billion: 'B' }.freeze

  def nice_view_count(view_count)
    precision = view_count < 1000 ? 3 : 2
    number_to_human(view_count, precision:, units: VIEW_COUNT_UNITS).delete(' ')
  end

  def nav_link_to(title, link, opts = {})
    is_active = current_page?(link) ||
      # We redirect home to /sites when user is logged in
      (current_page?(sites_path) && link == root_path) ||
      # Highlight Hub link for all Hub pages
      # FIXME: This is probably not going to be working, (but
      # maybe it doesn't matter since the active class doesn't
      # do much anyhow..?)
      (controller_name == 'hub' && link == '/hub') ||
      # Highlight Admin link for all Admin pages
      (controller_name == 'admin' && link == '/admin')

    icon = opts.delete(:icon)
    li_class = opts.delete(:li_class)

    content_tag :li, class: ['nav-item', li_class] do
      link_to link, opts.merge(class: "flex-column nav-link#{' active' if is_active}") do
        safe_join([bi_icon(icon), title].compact)
      end
    end
  end

  def tab_link_to(title, link, opts = {})
    is_active = current_page?(link)
    content_tag :li, class: 'nav-item' do
      link_to link, opts.merge(class: "nav-link#{' active' if is_active}") do
        title
      end
    end
  end

  def bi_icon(icon, opts = {})
    return unless icon

    opts.reverse_merge!(
      class: ['bi'].append(opts.delete(:class)).compact,
      height: '1.2em',
      width: '1.4em',
      style: "margin-top:-3px;margin-right:3px;#{opts.delete(:style)}")

    content_tag(:svg, opts) do
      content_tag(:use, nil, 'xlink:href' =>
        "#{asset_path('bootstrap-icons/bootstrap-icons.svg')}##{icon}")
    end
  end

  def display_none_when(condition)
    "display: #{condition ? 'none' : 'block'};"
  end

  def gravatar_url(email)
    "https://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email)}?d=identicon&s=80"
  end

  def libravatar_url(email)
    "https://www.libravatar.org/avatar/#{Digest::MD5.hexdigest(email)}?d=identicon&s=80"
  end

  def gravatar_image(user, opts = {})
    opts[:size] ||= 80
    opts[:class] ||= 'avatar'
    image_tag(gravatar_url(user.email), opts)
  end

  def libravatar_image(user, opts = {})
    opts[:size] ||= 80
    opts[:class] ||= 'avatar'
    image_tag(libravatar_url(user.email), opts)
  end

  def avatar_image(user, opts = {})
    user.use_libravatar? ? libravatar_image(user, opts) : gravatar_image(user, opts)
  end

  def bool_text(bool_val, true_text: 'Y', false_text: 'N')
    bool_val ? true_text : false_text
  end

  def bool_icon(bool_val)
    bool_val ?
      bi_icon('check-circle', fill: 'green') :
      bi_icon('dash-circle-dotted', fill: '#aaa')
  end

  def nice_timestamp(timestamp, brief: false)
    return '-' unless timestamp

    content_tag :span, title: timestamp.to_s do
      brief ? brief_time_ago_in_words(timestamp) : "#{time_ago_in_words(timestamp)} ago"
    end
  end

  def brief_time_ago_in_words(timestamp)
    "#{time_ago_in_words(timestamp).sub(/^(about|less than) /, '')} ago"
  end

  def nice_timespan(start_time, end_time, brief: false)
    return '-' unless start_time && end_time

    content_tag :span, title: end_time.to_s do
      distance_of_time_in_words(start_time, end_time, include_seconds: !brief).sub(/^(about|less than) /, '')
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
  # (Not used currently.)
  def span_with_title_truncated(full_text, truncate_length = 100)
    content_tag :span, title: full_text do
      truncate(full_text, length: truncate_length, separator: ' ')
    end
  end

  def nice_percentage(number, total, opts = {})
    number_to_percentage(100 * number / total, opts.reverse_merge(precision: 1))
  end

  def support_mail_to(opts = {})
    mail_to(Settings.support_email,
      opts.delete(:link_title) || Settings.support_email_name,
      opts.reverse_merge(target: '_blank'))
  end

  def github_history_url(branch_or_sha)
    "#{Settings.github_url}/commits/#{branch_or_sha}"
  end

  def github_history_link_to(title, sha = nil, opts = {})
    link_to(title, github_history_url(sha || title), { target: '_blank' }.reverse_merge(opts))
  end

  # See also lib/bootstrap_paginate_renderer.rb
  def will_paginate(coll_or_options = nil, options = {})
    if coll_or_options.is_a? Hash
      options = coll_or_options
      coll_or_options = nil
    end

    unless options[:renderer]
      options = options.merge renderer: BootstrapPaginateRenderer
    end

    super(*[coll_or_options, options].compact)
  end

  # Todo: Use this for all the menu links instead of just
  # these ones from the site history page
  #
  SHARED_LINK_CONTENT = {
    view: ['box-arrow-up-right', 'View'],
    download: ['download', 'Download'],
    restore: ['file-earmark-arrow-up', 'Restore as current version'],
    discard: ['trash', 'Discard'],
    upgrade: [['stars', { class: 'red-icon' }], 'Upgrade plan'],
  }.freeze

  def link_content(key)
    bi_icon_args, text = SHARED_LINK_CONTENT[key]
    bi_icon(*Array.wrap(bi_icon_args)) + text
  end

  # Silly helper to avoid long lines in haml due to very long strings in function
  # params. It works because haml allows a comma to split function calls lines and
  # this provides a way to have additional commas.
  #
  def text_join(*strings)
    strings.join(' ')
  end
end
