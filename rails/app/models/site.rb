class Site < ApplicationRecord
  belongs_to :user

  has_one_attached :tiddlywiki_file

  delegate :blob, to: :tiddlywiki_file
  delegate :byte_size, :key, :created_at, to: :blob, prefix: true

  delegate :name, :email, to: :user, prefix: true

  validates :name,
    presence: true,
    uniqueness: true,
    length: {
      # Let's reserve sites with one or two letter names
      minimum: 3,
      # RFC1035 says 63 is the maximum size of a subdomain...
      maximum: 63,
    },
    format: {
      # Must be only lowercase letters, numerals, and dashes
      # Must not have more than one consecutive dash
      # Must not start or end with a dash
      # (See also app/javascript/packs/application.js)
      without: / [^a-z0-9-] | -- | ^- | -$ /x,
      message: "'%{value}' is not allowed. Please choose a different site name.",
    },
    exclusion: {
      # Let's reserve a few common subdomains
      in: %w[
        www
        ftp
        pop
        imap
        smtp
        mail
        help
        faq
        support
        wiki
      ],
      message: "'%{value}' is reserved. Please choose a different site name.",
    }

  def url
    Settings.subdomain_site_url(name)
  end

  def is_public?
    !is_private?
  end

end
