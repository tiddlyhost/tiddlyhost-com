
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

    @active_weekly = User.where('last_sign_in_at > ?', 1.week.ago).count
    @active_monthly = User.where('last_sign_in_at > ?', 1.month.ago).count
    @active_daily = User.where('last_sign_in_at > ?', 1.day.ago).count

    @site_count = Site.count
    @never_updated_sites = Site.never_updated.count
    @private_count = Site.private_sites.count
    @public_count = Site.public_sites.count
    @public_non_searchable_count = Site.public_non_searchable.count
    @searchable_count = Site.searchable.count

    @tspot_site_count = TspotSite.no_stubs.count
    @owned_tspot_site_count = TspotSite.owned.count
    @saved_tspot_count = TspotSite.where.not(save_count: 0).count

    # See also fixup-scripts/clean-attachment-dupes.rb
    @dupe_attachments = ActiveStorage::Attachment.
      group(:record_type, :record_id).count.select{ |k, c| c > 1 }.count

  end

  SORT_OPTIONS = {
    accesses: 'access_count',
    blobmb: 'active_storage_blobs.byte_size',
    created: 'created_at',
    createdip: 'created_ip',
    currentsignin: 'current_sign_in_at',
    description: "NULLIF(sites.description, '')",
    email: 'email',
    empty: 'empties.name',
    gravatar: 'use_gravatar',
    id: 'id',
    lastaccess: 'accessed_at',
    lastsignin: 'last_sign_in_at',
    lastupdate: 'active_storage_blobs.created_at',
    logins: 'sign_in_count',
    name: 'name',
    owner: 'COALESCE(users.username, users.email)',
    plan: 'plan_id',
    private: 'is_private',
    saves: 'save_count',
    hub: 'is_searchable',
    rawmb: 'raw_byte_size',
    sites: 'COUNT(sites.id)',
    tspotsites: 'COUNT(tspot_sites.id)',
    username: "NULLIF(username, '')",
    version: 'tw_version',
    views: 'view_count',
  }.freeze

  NULL_ALWAYS_LAST = %w[
    username
    description
    owner
    version
  ]

  # s = sort
  # q = search (query)
  FILTER_PARAMS = %i[
    s
    q
    user
    owned
    saved
    private
    hub
    no_stub
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

  def raw_download
    klass = params[:tspot].present? ? TspotSite : Site
    site = klass.find(params[:id])
    download_html_content(site.file_download,
      "raw_#{klass.name.underscore}_#{site.id}_#{site.name}")
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
    @records = @records.where.not(user_id: nil) if params[:owned] == '1'
    @records = @records.where(user_id: nil) if params[:owned] == '0'

    @records = @records.where.not(save_count: 0) if params[:saved] == '1'
    @records = @records.where(save_count: 0) if params[:saved] == '0'

    @records = @records.where(is_private: true) if params[:private] == '1'
    @records = @records.where(is_private: false) if params[:private] == '0'

    @records = @records.where(is_searchable: true) if params[:hub] == '1'
    @records = @records.where(is_searchable: false) if params[:hub] == '0'

    @records = @records.no_stubs if params[:no_stub] == '1'
    @records = @records.stubs if params[:no_stub] == '0'

    @records = @records.where.not(password_digest: nil) if params[:new_pass] == '1'
    @records = @records.where(password_digest: nil) if params[:new_pass] == '0'

    @search = params[:q]
    @records = @records.admin_search_for(@search) if @search.present?

    # Sorting
    @sort_by = (params[:s].dup || 'created_desc')
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
