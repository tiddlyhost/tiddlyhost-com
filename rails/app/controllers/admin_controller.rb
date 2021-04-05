
class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin_user!

  def index
    @title = 'Stats'

    @view_count = Site.sum(:view_count)
    @tspot_view_count = TspotSite.sum(:access_count)
    @total_site_bytes = ActiveStorage::Blob.sum(:byte_size)

    @user_count = User.count
    @never_signed_in_users = User.where(sign_in_count: 0).count
    @signed_in_once_users = User.where(sign_in_count: 1).count

    @site_count = Site.count
    @never_updated_sites = Site.never_updated.count
    @private_count = Site.private_sites.count
    @public_count = Site.public_sites.count
    @public_non_searchable_count = Site.public_non_searchable.count
    @searchable_count = Site.searchable.count

    @tspot_site_count = TspotSite.where(exists: true).count
    @notexist_tspot_site_count = TspotSite.where(exists: false).count
    @owned_tspot_site_count = TspotSite.where("user_id IS NOT NULL").count
    @tspot_sites_with_storage = TspotSite.joins(:tiddlywiki_file_attachment).count

    # See also fixup-scripts/clean-attachment-dupes.rb
    @dupe_attachments = ActiveStorage::Attachment.
      group(:record_type, :record_id).count.select{ |k, c| c > 1 }.count

  end

  SORT_OPTIONS = {
    accesses: 'access_count',
    created: 'created_at',
    createdip: 'created_ip',
    currentsignin: 'current_sign_in_at',
    description: "NULLIF(sites.description, '')",
    email: 'email',
    empty: 'empties.name',
    exists: 'exists',
    gravatar: 'use_gravatar',
    id: 'id',
    lastaccess: 'accessed_at',
    lastsignin: 'last_sign_in_at',
    lastupdate: 'active_storage_blobs.created_at',
    logins: 'sign_in_count',
    name: 'name',
    owner: 'COALESCE(users.username, users.email)',
    plan: 'plans.name',
    private: 'is_private',
    saves: 'save_count',
    searchable: 'is_searchable',
    sites: 'COUNT(sites.id)',
    sizemb: 'active_storage_blobs.byte_size',
    tspotsites: 'COUNT(tspot_sites.id)',
    username: "NULLIF(username, '')",
    views: 'view_count',
  }.freeze

  NULL_ALWAYS_LAST = %w[
    username
    description
    owner
  ]

  FILTER_PARAMS = %i[
    sort
    search
    user
    exists
    owned
    saved
    private
    hub
  ]

  def users
    render_records User.left_joins(:sites, :tspot_sites).group(:id)
  end

  def sites
    render_records Site.left_joins(
      :user, :empty, :tiddlywiki_file_attachment, tiddlywiki_file_attachment: :blob)
  end

  def tspot_sites
    render_records TspotSite.left_joins(
      :user, :tiddlywiki_file_attachment, tiddlywiki_file_attachment: :blob)
  end

  private

  def render_records(records)
    @title = action_name.titleize
    @records = records

    # Filter by user
    if @user = User.find_by_id(params[:user])
      if action_name == 'users'
        @records = @records.where(id: @user.id)
        @title = "#{@user.username_or_email}'s Details"
      else
        @records = @records.where(user: @user)
        @title = "#{@user.username_or_email}'s #{@title}"
      end
    end

    # Filtering
    @records = @records.where(exists: true) if params[:exists] == '1'
    @records = @records.where(exists: false) if params[:exists] == '0'

    @records = @records.where.not(user_id: nil) if params[:owned] == '1'
    @records = @records.where(user_id: nil) if params[:owned] == '0'

    @records = @records.where.not(save_count: 0) if params[:saved] == '1'
    @records = @records.where(save_count: 0) if params[:saved] == '0'

    @records = @records.where(is_private: true) if params[:private] == '1'
    @records = @records.where(is_private: false) if params[:private] == '0'

    @records = @records.where(is_searchable: true) if params[:hub] == '1'
    @records = @records.where(is_searchable: false) if params[:hub] == '0'

    @search = params[:search]
    @records = @records.search_for(@search) if @search.present?

    # Sorting
    @sort_by = (params[:sort] || 'created_desc').sub(/_asc$/, '')
    null_always_last = NULL_ALWAYS_LAST.include?(@sort_by)
    @is_desc = @sort_by.sub!(/_desc$/, '')
    sort_field = SORT_OPTIONS[@sort_by.to_sym]
    desc_sql = @is_desc ? "DESC NULLS LAST" : "ASC NULLS #{null_always_last ? 'LAST' : 'FIRST'}"
    @records = @records.order(Arel.sql("#{sort_field} #{desc_sql}")) if sort_field

    # Pagination
    @records = @records.paginate(page: params[:page], per_page: 15)

    render action: :paginated_records
  end

end
