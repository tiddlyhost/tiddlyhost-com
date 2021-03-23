
module WithAccessCount

  def touch_accessed_at
    # Use update_column to avoid automatically touching updated_at
    update_column(:accessed_at, Time.now)
  end

  def increment_access_count
    # Use update_column to avoid automatically touching updated_at
    update_column(:access_count, access_count + 1)
  end

end
