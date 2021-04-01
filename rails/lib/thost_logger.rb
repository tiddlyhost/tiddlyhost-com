
class ThostLogger < Logger

  TH_LOG_FILE = '/var/log/app/app.log'

  # Only need one of these
  def self.thost_logger
    @_th_logger = self.new(TH_LOG_FILE)
  end

  # Skip the rest for now.
  #  %i[ debug info warn error fatal unknown ]
  def info(msg, request=nil)
    super(with_extra_request_info(msg, request))
  end

  def with_extra_request_info(msg, req=nil)
    return msg if req.nil?
    '%s - %s "%s%s%s" for %s (%s) "%s"' % [
      msg, req.request_method, req.protocol,
      req.host_with_port, req.filtered_path, req.ip,
      req.remote_ip, req.headers['HTTP_USER_AGENT']
    ]
  end

end
