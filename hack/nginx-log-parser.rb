#!/usr/bin/ruby

require 'json'
require 'csv'

# Regex to split out each field in an nginx log line
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

# Determine if a particular log line is for a site save
def is_site_save?(captures)
  (captures["request_method"] =~ /PUT|POST/) &&
    captures["request_uri"] == "/" &&
    captures["host"] =~ /[a-z-]+\.tiddlyhost\.com/
end

# Determine the OS based on the request user agent
def derive_os(user_agent)
  case user_agent
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
    "Other: #{user_agent}"
  end
end

site_save_lines = []
STDIN.read.lines.each do |raw|
  # Parse the log line using the regex above
  captures = log_regex.match(raw)&.named_captures || {}

  # Add an extra attribute for the os
  captures["os"] = derive_os(captures["http_user_agent"])

  # Keep only if it's a save request
  site_save_lines << { raw:, captures: } if is_site_save?(captures)
end

# Decide what to output
output = case ARGV[0]
when "csv"
  ->(line) { %w( time_local host os request_time ).map{ |attr| line[:captures][attr] }.to_csv }

when "allvalues"
  ->(line) { line[:captures].to_json }

else
  ->(line) { line[:raw] }
end

# Output
site_save_lines.each do |line|
  puts output[line]
end
