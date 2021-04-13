#
# Because we chose to keep sites and tspot sites in separate schema with
# unrelated models we need to do some extra work here.
#
# The goal is to produce a sorted, filtered, paginated list of site-ish
# records for the hub. Luckily it's not too hard thanks to Arel,
# WillPaginate::Collection and some creative hackery... :)
#
module HubQuery

  def self.paginated_sites(page:, per_page:, sort_by:, tag:, user:, search:)
    # Work with two separate queries
    qs = [
      Site.for_hub.with_blob.select(
        "'Site' as type", :id, :name, :view_count, "active_storage_blobs.created_at as blob_created_at"),

      TspotSite.for_hub.with_blob.select(
        "'TspotSite' as type", :id, :name, "access_count as view_count", "active_storage_blobs.created_at as blob_created_at"),
    ]

    # Apply filters
    qs.map! { |q| q.tagged_with(tag) } if tag.present?
    qs.map! { |q| q.where(user_id: user.id) } if user.present?
    qs.map! { |q| q.search_for(search) } if search.present?

    # Return paginated collection
    WillPaginate::Collection.create(page||1, per_page) do |pager|
      # Combine the two queries with a union and paginate the combined results
      sql = qs.map(&:to_sql).join(" UNION ") +
        " ORDER BY #{sort_by} LIMIT #{pager.per_page} OFFSET #{pager.offset}"

      # A mixed list of Site & TspotSite records
      results = ActiveRecord::Base.connection.execute(sql).pluck('type', 'id').map do |s_type, s_id|
        const_get(s_type).find(s_id)
      end

      pager.replace(results)
      pager.total_entries = qs.map{ |q| q.count(:id) }.sum
    end

  end

  def self.tags_for_searchable_sites
    tags = ActsAsTaggableOn::Tagging.where(
      taggable_id: Site.searchable.updated_at_least_once.pluck(:id) + TspotSite.searchable.pluck(:id),
      taggable_type: ['Site', 'TspotSite'])

    ActsAsTaggableOn::Tag.where(id: tags.pluck(:tag_id)).order('taggings_count desc');
  end

end
