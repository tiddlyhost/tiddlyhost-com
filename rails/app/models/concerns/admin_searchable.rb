
module AdminSearchable
  extend ActiveSupport::Concern

  included do

    # Admin search can also search by record id.
    # Assume there's already a search_for scope defined.
    #
    scope :admin_search_for, ->(search_text) {
      search_for(search_text).
      or(where(id: search_text)) }

  end

end
