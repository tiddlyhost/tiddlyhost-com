# frozen_string_literal: true

module EmptyMigrationHelper

  def self.apply_empty_changes(yaml_in)
    YAML.load(yaml_in.strip_heredoc).each do |name, attrs|
      Empty.find_or_create_by(name: name).update(attrs)
    end
  end

end
