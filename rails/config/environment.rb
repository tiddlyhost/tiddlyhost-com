# Load the Rails application.
require_relative "application"

# Initialize the Rails application.
Rails.application.initialize!

# There should never be multiple attachments for the has_one_attachment
# :tiddlywiki_file association, but if there are, it's much better to use
# the newest one not the oldest. This scope changes the behavior of the
# .first method to return the newest record. (See commit message for
# further explanations.)
#
# It seems we need to do this after the railstie initialization for active
# storage so that's why it's here. Todo: Figure out a better place to put it.
#
ActiveStorage::Attachment.class_eval do
  default_scope { order('created_at DESC') }
end
