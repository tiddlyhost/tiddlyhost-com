
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

  def kind
    th_file.kind
  end

  def tiddlywiki_version
    th_file.tiddlywiki_version
  end

  def long_title
    "#{title} (#{th_file.tiddlywiki_version})#{' - Recommended' if is_default?}"
  end

  def self.versions
    self.for_select.map{ |e| {name: e.name, version: e.tiddlywiki_version, kind: e.kind } }
  end

end
