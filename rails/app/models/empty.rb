
class Empty < ApplicationRecord
  include WithDefault

  scope :enabled, ->{ where(enabled: true) }

  def self.for_select
    enabled.order(:id).to_a.select(&:present?)
  end

  def th_file
    ThFile.from_empty(name)
  end

  def present?
    ThFile.empty_file_present?(name)
  end

  def html
    th_file.to_html
  end

  def long_title
    "#{title} (#{th_file.tiddlywiki_version})#{' - Recommended' if is_default?}"
  end

  # Returns a hash of names and versions
  def self.versions
    Hash[ enabled.map{ |e| [e.name, e.th_file.tiddlywiki_version] } ]
  end

end
