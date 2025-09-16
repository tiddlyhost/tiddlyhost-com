class Empty < ApplicationRecord
  include WithDefault

  scope :enabled, -> { where(enabled: true) }

  def self.for_select
    enabled.order(:display_order).to_a.select(&:file_present?)
  end

  def th_file
    ThFile.from_empty(name)
  end

  def file_present?
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

  def long_tooltip
    pretty_link_text = info_link.sub(%r{^https?://}, '').sub(%r{/$}, '')
    %(#{tooltip} Source: <a href="#{info_link}" target="_blank">#{pretty_link_text} ⇗</a>)
  end

  def self.versions
    self.for_select.map { |e| { name: e.name, version: e.tiddlywiki_version, kind: e.kind, title: e.title } }
  end
end
