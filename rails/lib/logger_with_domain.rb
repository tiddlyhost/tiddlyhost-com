#
# As per https://stackoverflow.com/questions/7214166/full-urls-in-rails-logs
# Used in config/application.rb
#
# Will log like this:
#   Started POST "https://aaa.tiddlyhost.local/" for 172.20.0.1 at 2021-03-26 08:10:39 +0000
#
# Instead of like this:
#    Started POST "/" for 172.20.0.1 at 2021-03-26 08:10:39 +0000
#
class LoggerWithDomain < Rails::Rack::Logger

  def started_request_message(request)
    'Started %s "%s%s%s" for %s at %s' % [
      request.request_method,
      request.protocol,
      request.host_with_port,
      request.filtered_path,
      request.ip,
      Time.now.to_default_s ]
  end

end
