
module AdminHelper

  def link_to_user_sites(text, user, opts={})
    link_to(text, { controller: :admin,
      action: opts.delete(:action) || params[:action],
      user_id: user.id }, opts)
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
