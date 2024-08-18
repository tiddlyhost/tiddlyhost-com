class TweakAcceptHeader
  def initialize(app)
    @app = app
  end

  def call(env)
    # When TiddlyWiki does a HEAD request to retrieve an ETag it sets the accept
    # header to "*/*;charset=UTF-8" which Rails considers an invalid mime type,
    # and responds with a 406 Not Acceptable. Tweak the header to convince Rails
    # to provide a value response to TiddlyWiki can get the Etag.
    # See https://github.com/TiddlyWiki/TiddlyWiki5/blob/c51a233627/core/modules/savers/put.js#L23
    # Any valid accept header should be fine. Since it's a HEAD request I can't
    # see how it would matter. Curiously the OPTIONS that TiddlyWiki does to detect
    # Dav support uses "application/json".
    #
    if env['REQUEST_METHOD'] == 'HEAD' && env['HTTP_ACCEPT'] == '*/*;charset=UTF-8'
      env['HTTP_ACCEPT'] = '*/*'
    end

    @app.call(env)
  end
end
