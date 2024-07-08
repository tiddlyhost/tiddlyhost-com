#
# Useful data for bringing up a new development environment
#
[
  UserType,
  Empty

].each do |klass|
  seed_file = "#{Rails.root}/db/seeds/#{klass.table_name}.yml"
  klass.create!(YAML.load_file(seed_file))
end
