
require 'aws-sdk-s3'

class TspotFetcher

  def initialize(site_name, secrets=nil)
    @name = site_name

    # No need for a real S3 client in test suite
    unless Rails.env.test?
      secrets ||= Settings.secrets(:dreamobjects)
      @bucket_name = secrets[:bucket_name]
      @s3_client = Aws::S3::Client.new(
        endpoint: secrets[:endpoint_url],
        region: secrets[:region],
        access_key_id: secrets[:aws_server_public_key],
        secret_access_key: secrets[:aws_server_secret_key])
    end
  end

  attr_reader :name

  def html_file
    @_html ||= site_file('index.html')
  end

  def htpasswd_file
    @_htpasswd ||= site_file('.htpasswd')
  end

  def htaccess_file
    @_htaccess ||= site_file('.htaccess')
  end

  def exists?
    htaccess_file.present?
  end

  def is_public?
    # The .htaccess file for public Tiddlyspot sites should match this.
    # (Could probably be less specific, but let's try it this way.)
    htaccess_file =~
      %r{\n## --- public site ---\n\n# protect only controlpanel\n\n<files "controlpanel\.cgi">\n}
  end

  def is_private?
    !is_public?
  end

  # This doesn't really belong here, but never mind
  def self.passwd_match?(given_username, given_passwd, htpasswd)
    return false unless \
      given_username.present? && given_passwd.present? && htpasswd.present?

    username, passwd_crypt = htpasswd.split(':')
    salt = username[0,2]
    given_username == username && given_passwd.crypt(salt) == passwd_crypt
  end

  private

  def site_file(file_name)
    fetch_key(site_key(file_name))
  end

  def site_key(file_name)
    exploded_path = "#{@name[0,1]}/#{@name[0,2]}/#{@name[0,3]}/#{@name}"
    "ts/sites/#{exploded_path}/#{file_name}"
  end

  def fetch_key(key)
    begin
      @s3_client.get_object(bucket: @bucket_name, key: key).body.read
    rescue Aws::S3::Errors::NoSuchKey
      nil
    end
  end

end
