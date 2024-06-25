# frozen_string_literal: true

#
# Useful data for bringing up a new development environment
#
[
  UserType,
  Empty

].each do |klass|
  seed_file = "#{Rails.root}/db/seeds/#{klass.table_name}.yml"
  klass.create!(YAML.load(File.read(seed_file)))
end
