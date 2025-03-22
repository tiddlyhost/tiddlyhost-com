class EmptyDescriptionPunctuation < ActiveRecord::Migration[7.1]
  # Some descriptions end with a full stop and some don't.
  # This is to make them all consistent.

  def empties_to_fix
    Empty.where(name: %w[tw5 prerelease feather tw5x])
  end

  def up
    empties_to_fix.each { |e| e.update(description: "#{e.description}.") }
  end

  def down
    empties_to_fix.each { |e| e.update(description: e.description.sub(/\.$/, '')) }
  end
end
