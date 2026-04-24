require 'resolv'

class DnsVerifier
  NAMESERVERS = ['8.8.8.8', '1.1.1.1'].freeze
  TIMEOUT = 10

  def self.check_txt_record(domain, expected_value)
    records = lookup_txt_records(domain)

    if records.empty?
      { success: false, error: "No TXT record found at #{domain}" }
    elsif records.include?(expected_value)
      { success: true }
    else
      { success: false, error: "TXT record found but value does not match (found: #{records.join(', ')})" }
    end
  rescue Resolv::ResolvError => e
    { success: false, error: "DNS resolution error: #{e.message}" }
  rescue Resolv::ResolvTimeout
    { success: false, error: "DNS lookup timed out after #{TIMEOUT} seconds" }
  end

  def self.lookup_txt_records(domain)
    records = []
    Resolv::DNS.open(nameserver: NAMESERVERS, ndots: 1) do |dns|
      dns.timeouts = TIMEOUT
      resources = dns.getresources(domain, Resolv::DNS::Resource::IN::TXT)
      resources.each do |r|
        records.concat(r.strings)
      end
    end
    records
  end
end
