
class Empty < ApplicationRecord

  scope :enabled, ->{ where(enabled: true) }

  def self.default
    find_by_name(Settings.default_empty_name)
  end

  def self.for_select
    enabled.order(:id)
  end

  def th_file
    ThFile.from_empty(name)
  end

  def html
    th_file.to_html
  end

  def long_title
    "#{title} (#{th_file.tiddlywiki_version})"
  end

  # Returns a hash of names and versions
  def self.versions
    Hash[ enabled.map{ |e| [e.name, e.th_file.tiddlywiki_version] } ]
  end

end
