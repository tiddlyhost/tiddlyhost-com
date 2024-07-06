# frozen_string_literal: true

#
# Because we chose to keep sites and tspot sites in separate schema with
# unrelated models we need to do some extra work here.
#
# The goal is to produce a sorted, filtered, paginated list of site-ish
# records for the hub. Luckily it's not too hard thanks to Arel,
# WillPaginate::Collection and some creative hackery... :)
#
module HubQuery
  # TODO: Consider if we really need to join the blobs table. There is so much
  # complexity here related to the 'distinct on' and picking out the latest blob,
  # and the only real benefit is being able to access the blob's created at timestamp
  # to know when the site was last saved. Actually the sites updated_at is almost as
  # good so maybe it's not worth all the hoop jumping. Or we could add another
  # timestamp for saved_at and have it touched only when a save happens.

  def self.sites_for_user(user, sort_by:)
    # Not really paginated or hub related...
    # Todo: Cap site count per user or do pagination
    paginated_sites(
      page: nil, per_page: 1000, sort_by: sort_by, tag: nil, user: user, search: nil, for_hub: false,
      extra_fields_in_select: [
        :tw_kind,
        :tw_version,
        :is_private,
        :is_searchable,
        :raw_byte_size,
        'not is_searchable AS not_searchable',
      ])
  end

  def self.paginated_sites(page:, per_page:, sort_by:, templates_only: false, tag:, user:, search:, kind: nil, for_hub: true, extra_fields_in_select: [])
    # Work with two separate queries, one for each model
    qs = [
      #
      # The blob joins can create multiple rows per site since there might
      # be multiple attachments. The distinct collapses them down to one row
      # per site, and the `blob_created_at DESC` (hopefully) means the row with
      # the newest blob is the one that is kept, which is exactly what is needed.
      #
      Site.with_blobs_for_query.not_deleted.select(
        'DISTINCT ON (type, id) ' +
        "'Site' AS type",
        :id,
        :name,
        :tw_version,
        :view_count,
        :created_at,
        :allow_public_clone,
        :clone_count,
        'active_storage_blobs.created_at AS blob_created_at',
        'RANDOM() AS rand_sort',
        # Trim off Feather Wiki name prefixes for sorting, e.g. Warbler_
        "REGEXP_REPLACE(tw_version, '^[A-Za-z]+_', '') as tw_version_trimmed",
        *extra_fields_in_select
      ),

      TspotSite.with_blobs_for_query.not_deleted.select(
        'DISTINCT ON (type, id) ' +
        "'TspotSite' AS type",
        :id,
        :name,
        :tw_version,
        'access_count AS view_count',
        'NULL AS created_at',
        'false AS allow_public_clone',
        '0 AS clone_count',
        'CASE WHEN save_count = 0 THEN NULL ELSE active_storage_blobs.created_at END AS blob_created_at',
        'RANDOM() AS rand_sort',
        # Trim off Feather Wiki name prefixes for sorting, e.g. Warbler_
        "REGEXP_REPLACE(tw_version, '^[A-Za-z]+_', '') as tw_version_trimmed",
        *extra_fields_in_select
      ),
    ]

    # Apply filters
    qs.map! { |q| q.for_hub } if for_hub
    qs.map! { |q| q.templates_only } if templates_only
    qs.map! { |q| q.tagged_with(tag) } if tag.present?
    qs.map! { |q| q.where(user_id: user.id) } if user.present?
    qs.map! { |q| q.search_for(search) } if search.present?

    kind = ['tw5', 'tw5x'] if kind == 'tw'
    qs.map! { |q| q.where(tw_kind: kind) } if kind.present?

    # The idea here is the row selected by the DISTINCT ON should be
    # the most recent one, i.e. with the newest blob_created_at.
    # 1, 2 here means the first two columns, i.e. type and id.
    qs.map! { |q| q.order('1, 2, blob_created_at DESC') }

    # Return paginated collection
    WillPaginate::Collection.create(page || 1, per_page) do |pager|
      # Combine the two queries with a union and apply the sorting
      full_query_sql = qs.map(&:to_sql).map { |q| "( #{q} )" }.join(' UNION ') + "ORDER BY #{sort_by}, 1, 2 DESC"

      # For paginated results
      paged_query_sql = "#{full_query_sql} LIMIT #{pager.per_page} OFFSET #{pager.offset}"

      # Returns a mix of Site & TspotSite records
      results = ActiveRecord::Base.connection.execute(paged_query_sql).pluck('type', 'id').map do |s_type, s_id|
        const_get(s_type).find(s_id)
      end
      pager.replace(results)

      # Find the total result count
      result_count = ActiveRecord::Base.count_by_sql("select count(*) from (#{full_query_sql}) as foo")
      pager.total_entries = result_count
    end
  end

  def self.most_used_tags(for_templates: false)
    # We want tags from just the sites that are visible in the hub

    from_sites = Site.searchable.updated_at_least_once
    from_tspot_sites = TspotSite.searchable

    if for_templates
      from_sites = from_sites.where(allow_public_clone: true)
      from_tspot_sites = from_tspot_sites.where('1 = 0')
    end

    tagging = ActsAsTaggableOn::Tagging.where(
      taggable_id: from_sites.pluck(:id),
      taggable_type: 'Site'
    ).or(ActsAsTaggableOn::Tagging.where(
      taggable_id: from_tspot_sites.pluck(:id),
      taggable_type: 'TspotSite'
    ))

    # Do our own counts because the built in taggings_count value
    # is for all sites, not just sites visible in the hub
    tagging.
      group_by { |t| t.tag.name }.
      map { |k, v| [k, -v.count] }.
      sort_by(&:last).
      map(&:first).
      reject { |tag_name| tag_name.in?(Settings.secrets(:unfeatured_tags) || []) }
  end
end
