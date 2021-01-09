module ApplicationHelper

  def nav_link_to(title, link, opts={})
    content_tag :li, class: 'nav-item' do
      link_to title, link, opts.merge(class: "nav-link#{' active' if current_page?(link)}")
    end
  end
end
