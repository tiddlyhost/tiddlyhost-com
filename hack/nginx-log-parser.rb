#!/usr/bin/ruby

log_regex = /
  ^                                     # Start of line
  (?<prefix>\S+)\s+\|                   # Docker image log prefix
  \s+(?<remote_addr>\S+)                # Remote address
  \s+-\s+                               # Literal " - "
  (?<remote_user>\S+)                   # Remote user (may be '-')
  \s+\[(?<time_local>[^\]]+)\]          # Time in square brackets
  \s+"(?<request_method>\S+)            # Request method
  \s+(?<scheme>\S+):\/\/                # Scheme (e.g., http or https)
  (?<host>[^\/]+)                       # Host
  (?<request_uri>\S+)                   # Request URI
  \s+(?<server_protocol>\S+)"           # Protocol
  \s+(?<status>\d+)                     # Status code
  \s+(?<body_bytes_sent>\d+)            # Bytes sent
  \s+"(?<http_referer>[^"]*)"           # Referer in quotes
  \s+"(?<http_user_agent>[^"]*)"        # User-Agent in quotes
  \s+"(?<http_x_forwarded_for>[^"]*)"   # X-Forwarded-For in quotes
  \s+rt=(?<request_time>\S+)            # Request time
  \s+uct=(?<upstream_connect_time>\S+)  # Upstream connect time
  \s+uht=(?<upstream_header_time>\S+)   # Upstream header time
  \s+urt=(?<upstream_response_time>\S+) # Upstream response time
  $                                     # End of line
/x


def is_site_save?
  (@request_method == "PUT" || @request_method == "POST") && @request_uri == "/" && @host =~ /[a-z-]+\.tiddlyhost\.com/
end

def os
  case @http_user_agent
  when /\(Windows/
    "Windows"
  when /\(Linux/, /\(X11/
    "Linux"
  when /\(Macintosh/, /\(PPC Mac/
    "Mac"
  when /\(iPad/
    "iPad"
  when /\(iPhone/
    "iPhone"
  when /\(Android/
    "Android"
  when /^curl/
    "curl"
  else
    "Other: #{@http_user_agent}"
  end
end

output = []
ARGF.each do |line|
  match = log_regex.match(line)
  if match

    match.names.each do |n|
      #puts "@#{n} = #{match[n]}"
      instance_variable_set("@#{n}", match[n])
    end

    #puts @request_method
    if is_site_save?
      output << {request_time: @request_time, os: os}
    end
  end
end

sorted = output.sort_by{|line| [line[:os], line[:request_time].to_f]}

sorted.each do |line|
  puts [line[:os],line[:request_time]].join(",")
end
