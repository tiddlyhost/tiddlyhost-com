
module WithDefault
  extend ActiveSupport::Concern

  class_methods do
    def default_name
      Settings.send(:"default_#{name.underscore}_name")
    end

    def default
      find_by_name(default_name)
    end

    def default_id
      default.id
    end

    def is_default?(record)
      record == default
    end
  end

  def is_default?
    self.class.is_default?(self)
  end

end
