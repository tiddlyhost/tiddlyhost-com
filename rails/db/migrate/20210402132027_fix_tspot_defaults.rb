class FixTspotDefaults < ActiveRecord::Migration[6.1]

  def up
    change_column_default :tspot_sites, :is_searchable, from: nil, to: false
    change_column_default :tspot_sites, :is_private, from: nil, to: false

    TspotSite.where(is_searchable: nil).update_all(is_searchable: false)
    TspotSite.where(is_private: nil).update_all(is_private: false)
  end

  def down
    change_column_default :tspot_sites, :is_searchable, from: false, to: nil
    change_column_default :tspot_sites, :is_private, from: false, to: nil
  end

end
