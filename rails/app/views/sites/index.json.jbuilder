# frozen_string_literal: true

json.array! @sites, partial: 'sites/site', as: :site
