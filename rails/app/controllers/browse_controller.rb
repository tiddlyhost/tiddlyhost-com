class BrowseController < HubController
  private

  def set_default_title
    @thing_name = 'Site'
    @default_title = 'Browse'
    @explanation_text = %(
      Discover content created and shared by Tiddlyhost users.
    ).squish
  end
end
