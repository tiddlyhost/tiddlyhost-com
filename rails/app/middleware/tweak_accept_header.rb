class TweakAcceptHeader
  def initialize(app)
    @app = app
  end

  def call(env)
    # When TiddlyWiki does a HEAD request to retrieve an ETag it sets the accept
    # header to "*/*;charset=UTF-8" which Rails considers an invalid mime type,
    # and responds with a 406 Not Acceptable. Tweak the header to convince Rails
    # to provide a valid response so TiddlyWiki can get the Etag.
    # See also https://github.com/TiddlyWiki/TiddlyWiki5/pull/8547 .
    #
    if env['REQUEST_METHOD'] == 'HEAD' && env['HTTP_ACCEPT'] == '*/*;charset=UTF-8'
      env['HTTP_ACCEPT'] = '*/*'
    end

    @app.call(env)
  end
end
