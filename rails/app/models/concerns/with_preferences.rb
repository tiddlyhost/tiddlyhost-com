module WithPreferences
  extend ActiveSupport::Concern

  included do
    self::PREFERENCES.each do |pref_name, allowed_values|
      define_method("#{pref_name}_pref") do
        default_value = allowed_values.first
        preferences.fetch(pref_name.to_s, default_value)
      end

      define_method("#{pref_name}_pref=") do |value|
        raise ArgumentError, "#{pref_name} value \"#{value}\" must be one of #{allowed_values.inspect}" unless allowed_values.include?(value)

        update(preferences: preferences.merge(pref_name.to_s => value))
      end

      define_method("#{pref_name}_pref_next") do
        current_value = send("#{pref_name}_pref")
        CycleHelper.cycle_next(current_value, allowed_values)
      end

      define_method("#{pref_name}_pref_cycle") do
        new_value = send("#{pref_name}_pref_next")
        send("#{pref_name}_pref=", new_value)
        new_value
      end
    end
  end
end
