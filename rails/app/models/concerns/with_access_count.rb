
module WithAccessCount

  def touch_accessed_at
    gentle_touch_timestamp(:accessed_at)
  end

  def increment_access_count
    gentle_increment_count(:access_count)
  end

  def increment_save_count
    gentle_increment_count(:save_count)
  end

  # Actually only for Site
  def increment_view_count
    gentle_increment_count(:view_count)
  end

  private

  def gentle_touch_timestamp(field_name)
    # Use update_column to avoid automatically touching updated_at
    update_column(field_name, Time.now)
  end

  def gentle_increment_count(field_name)
    # Use update_column to avoid automatically touching updated_at
    update_column(field_name, send(field_name) + 1)
  end

end
