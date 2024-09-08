class TemplatesController < HubController
  private

  def set_default_title
    @thing_name = 'Template'
    @default_title = 'Templates'
    @explanation_text = %(
      Templates are useful or interesting customized editions of TiddlyWiki, created by
      Tiddlyhost users, that you can copy and use for yourself. Click "Clone" to create
      a site on Tiddlyhost using a template, or click "Download" to download a copy to
      use locally.
    ).squish
  end
end
