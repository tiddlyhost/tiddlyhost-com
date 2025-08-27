module CycleHelper
  def self.cycle_next(current_val, list_of_vals)
    # Choose 0 as the default index since in my use cases
    # often the first item is used as the default value.
    # Using -1 would also make sense.
    default_index = 0

    # Find what position the current item is in the list
    current_index = list_of_vals.find_index(current_val) || default_index

    # Modulo so we loop back to the start if we at the last val
    list_of_vals[(current_index + 1) % list_of_vals.length]
  end
end
