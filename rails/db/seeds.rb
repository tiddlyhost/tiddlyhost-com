#
# Originally this was in a PopulatePlans migration
# but then the table and model was renamed.
#
UserType.create!([
  {name: 'basic'},
  {name: 'superuser'}
])
