
class Empty < ApplicationRecord

  scope :enabled, ->{ where(enabled: true) }

  DEFAULT = 'tw5'

  def self.default_empty
    find_by_name(DEFAULT)
  end

  def self.empties_for_select
    enabled.order(:id)
  end

  def th_file
    ThFile.from_empty(name)
  end

  def html
    th_file.to_html
  end

  # Returns a hash of names and versions
  def self.versions
    Hash[ enabled.map{ |e| [e.name, e.th_file.tiddlywiki_version] } ]
  end

end
