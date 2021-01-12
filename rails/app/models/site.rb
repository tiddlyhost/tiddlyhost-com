class Site < ApplicationRecord
  belongs_to :user

  has_one_attached :tiddlywiki_file

  validates :name,
    presence: true,
    uniqueness: true,
    length: { in: 3..63 },
    format: { without: /--|\A-|-\Z|[^a-z-]/ }

  def url
    ActionDispatch::Http::URL.full_url_for(Settings.url_defaults.merge(subdomain: name))
  end

  def is_public?
    !is_private?
  end

end
