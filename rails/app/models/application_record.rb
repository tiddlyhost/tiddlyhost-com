class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def th_log(msg)
    ThostLogger.thost_logger.info(msg)
  end
end
