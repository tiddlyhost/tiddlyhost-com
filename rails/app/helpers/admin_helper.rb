
module AdminHelper

  def link_to_user_sites(text, user, opts={})
    link_to(text, {controller: :admin, action: :sites, user_id: user.id}, opts)
  end

end
