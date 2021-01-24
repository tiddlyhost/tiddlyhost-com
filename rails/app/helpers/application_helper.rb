module ApplicationHelper

  def nav_link_to(title, link, opts={})
    content_tag :li, class: 'nav-item' do
      link_to title, link, opts.merge(class: "nav-link#{' active' if current_page?(link)}")

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

end
