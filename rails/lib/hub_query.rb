#
# Because we chose to keep sites and tspot sites in separate schema with
# unrelated models we need to do some extra work here.
#
# The goal is to produce a sorted, filtered, paginated list of site-ish
# records for the hub. Luckily it's not too hard thanks to Arel,
# WillPaginate::Collection and some creative hackery... :)
#
module HubQuery

  def self.sites_for_user(user, sort_by:)
    # Not really paginated or hub related...
    # Todo: Cap site count per user or do pagination
    paginated_sites(
      page: nil, per_page: 1000, sort_by: sort_by, tag: nil, user: user, search: nil, for_hub: false,
      extra_fields_in_select: [
        :tw_kind, :tw_version, :is_private, :is_searchable,
        # Have a rough guess if it was never set
        'COALESCE(raw_byte_size, active_storage_blobs.byte_size * 4) as raw_size',
        'not is_searchable as not_searchable', 'active_storage_blobs.byte_size as size'
      ])
  end

  def self.paginated_sites(page:, per_page:, sort_by:, tag:, user:, search:, for_hub: true, extra_fields_in_select: [])
    # Work with two separate queries
    qs = [
      Site.with_blob.select(
        "'Site' AS type", :id, :name, :view_count, :created_at,
        "active_storage_blobs.created_at AS blob_created_at",
        "RANDOM() as rand_sort",
        *extra_fields_in_select),

      TspotSite.with_blob.select(
        "'TspotSite' AS type", :id, :name, "access_count AS view_count", "NULL AS created_at",
        "CASE WHEN save_count = 0 THEN NULL ELSE active_storage_blobs.created_at END AS blob_created_at",
        "RANDOM() as rand_sort",
        *extra_fields_in_select),
    ]

    # Apply filters
    qs.map! { |q| q.for_hub } if for_hub
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

  def self.most_used_tags
    # Find just the records for sites that are visible in the hub
    tagging = ActsAsTaggableOn::Tagging.where(
      taggable_id: Site.searchable.updated_at_least_once.pluck(:id),
      taggable_type: 'Site'
    ).or(ActsAsTaggableOn::Tagging.where(
      taggable_id: TspotSite.searchable.pluck(:id),
      taggable_type: 'TspotSite'
    ))

    # Do our own counts because the built in taggings_count value
    # is for all sites, not just sites visible in the hub
    tagging.
      group_by{ |t| t.tag.name }.
      map{ |k, v| [k, -v.count] }.
      sort_by(&:last).
      map(&:first).
      reject{ |tag_name| tag_name.in?(Settings.secrets(:unfeatured_tags)||[]) }
  end

end
