require 'csv'

class AdminController < ApplicationController
  include AdminChartData

  before_action :authenticate_user!
  before_action :require_admin_user!

  before_action :enable_chart_js, only: [:charts]

  def index
    @title = 'Stats'

    @view_count = Site.sum(:access_count)
    @tspot_view_count = TspotSite.sum(:access_count)
    @total_site_bytes = ActiveStorage::Blob.sum(:byte_size)

    @user_count = User.count
    @subscription_count = User.with_subscriptions_active.count
    @alt_subscription_count = User.where('alt_subscription IS NOT NULL').
      where.not(id: Settings.secrets(:my_account_ids) || []).count

    @never_signed_in_users = User.signed_in_never.count
    @signed_in_once_users = User.signed_in_once.count

    active_users = User.signed_in_more_than_once
    @active_daily = active_users.active_day.count
    @active_weekly = active_users.active_week.count
    @active_monthly = active_users.active_month.count

    @site_count = Site.count
    @never_updated_sites = Site.never_updated.count
    @private_count = Site.private_sites.count
    @public_count = Site.public_sites.count
    @public_non_searchable_count = Site.public_non_searchable.count
    @searchable_count = Site.searchable.count

    @tspot_site_count = TspotSite.no_stubs.count
    @owned_tspot_site_count = TspotSite.owned.count
    @saved_tspot_count = TspotSite.where.not(save_count: 0).count

    @jobs_count = Delayed::Job.count

    @jobs_running_count = Delayed::Job.where.not(locked_by: nil).count
    @jobs_running_since = Delayed::Job.where.not(locked_by: nil).first&.locked_at
    @jobs_running_sites = GenerateThumbnailJob.running_sites
    @jobs_alert = @jobs_running_since && @jobs_running_since < 10.minutes.ago
  end

  include SortAndFilterLinkHelper

  SORT_OPTIONS = {
    accesses: 'access_count',
    clone: 'cloned_from_id',
    clones: 'clone_count',
    created: 'created_at',
    createdip: 'created_ip',
    currentsignin: 'current_sign_in_at',
    description: "NULLIF(sites.description, '')",
    email: 'email',
    empty: 'empties.name',
    av: ['use_gravatar', 'use_libravatar'],
    id: 'id',
    iframes: 'allow_in_iframe',
    kind: 'tw_kind',
    lastaccess: 'accessed_at',
    lastsignin: 'last_sign_in_at',
    lastupdate: 'updated_at',
    logins: 'sign_in_count',
    name: 'name',
    owner: 'COALESCE(users.username, users.email)',
    type: 'user_type_id',
    # There's probably only one of these but it needs
    # to be an aggregate due to the group by user.id
    subscr: ['MAX(pay_subscriptions.status)', 'MAX(pay_subscriptions.id)'],
    private: 'is_private',
    put: 'prefer_put_saver',
    saves: 'save_count',
    hub: 'is_searchable',
    rawmb: 'raw_byte_size',
    sites: 'COUNT(sites.id)',
    storage: 'storage_service',
    template: 'allow_public_clone',
    tspotsites: 'COUNT(tspot_sites.id)',
    upload: 'prefer_upload_saver',
    username: "NULLIF(username, '')",
    version: 'tw_version',
    versions: 'COUNT(active_storage_blobs.id)',
    views: 'view_count',
  }.freeze

  NULL_ALWAYS_LAST = %w[
    username
    description
    owner
    version
    kind
    clone
    subscr
  ].freeze

  FILTER_PARAMS = {
    owned: {
      '1' => { title: 'owned', filter: ->(r) { r.where.not(user_id: nil) } },
      '0' => { title: 'unowned', filter: ->(r) { r.where(user_id: nil) } },
    },

    saved: {
      '1' => { title: 'saved', filter: ->(r) { r.where.not(save_count: 0) } },
      '0' => { title: 'unsaved', filter: ->(r) { r.where(save_count: 0) } },
    },

    private: {
      '1' => { title: 'private', filter: ->(r) { r.where.not(is_private: false) } },
      '0' => { title: 'public', filter: ->(r) { r.where(is_private: false) } },
    },

    hub: {
      '1' => { title: 'hub', filter: ->(r) { r.where.not(is_searchable: false) } },
      '0' => { title: 'non-hub', filter: ->(r) { r.where(is_searchable: false) } },
    },

    template: {
      '1' => { title: 'template', filter: ->(r) { r.where.not(allow_public_clone: false) } },
      '0' => { title: 'non-template', filter: ->(r) { r.where(allow_public_clone: false) } },
    },

    no_stub: {
      '1' => { title: 'non-stub', filter: lambda(&:no_stubs) },
      '0' => { title: 'stub', filter: lambda(&:stubs) },
    },

    new_pass: {
      '1' => { title: 'new passwd', filter: ->(r) { r.where.not(password_digest: nil) } },
      '0' => { title: 'legacy passwd', filter: ->(r) { r.where(password_digest: nil) } },
    },

    deleted: {
      '1' => { title: 'deleted', filter: ->(r) { r.where.not(deleted: false) } },
      '0' => { title: 'not deleted', filter: ->(r) { r.where(deleted: false) } },
    },

    kind: {
      filter: ->(r, kind) { r.where(tw_kind: kind) },
    },

    user: {
      # See filter_by_user_maybe below
    },

    q: {
      filter: ->(r, search) { r.admin_search_for(search) },
    },

    signedin: {
      '1' => { title: 'signed in', filter: ->(r) { r.where('sign_in_count > 0') } },
      '0' => { title: 'never signed in', filter: ->(r) { r.where('sign_in_count = 0') } },
    },

    subscription: {
      '2' => { title: 'current', filter: ->(r) { r.where("pay_subscriptions.status = 'active' OR NOT alt_subscription IS NULL") } },
      '1' => { title: 'any status', filter: ->(r) { r.where.not('pay_subscriptions.id IS NULL') } },
      '0' => { title: 'no subscription', filter: ->(r) { r.where('pay_subscriptions.id IS NULL and alt_subscription IS NULL') } },
    },

  }.freeze

  def users
    render_records User.left_joins(:sites, :tspot_sites).join_subscriptions.group(:id)
  end

  def sites
    render_records Site.left_joins(:user, :empty).with_blobs_for_query.group(:id)
  end

  def tspot_sites
    render_records TspotSite.left_joins(:user).with_blobs_for_query.group(:id)
  end

  def etc
  end

  def raw_download
    klass = params[:type] == 'TspotSite' ? TspotSite : Site
    site = klass.find(params[:id])
    blob_id = params[:blob_id]

    raw_html = site.file_download(blob_id)
    download_filename = "raw_#{klass.name.underscore}_#{site.id}_#{blob_id}_#{site.name}"
    download_html_content(raw_html, download_filename)
  end

  def boom
    raise 'Boom!'
  end

  def pool_stats
    render json: ActiveRecord::Base.connection.pool.stat.to_json
  end

  def charts
    @chart_data = chart_data(params[:chart])
  end

  private

  def default_sort
    case action_name
    when 'tspot_sites'
      :lastupdate_desc
    else
      :created_desc
    end
  end

  def render_records(records)
    @title = action_name.titleize
    @records = records

    # Filtering
    filter_by_user_maybe
    @records = filter_results(@records)

    # Sorting
    @records = @records.order(Arel.sql(sort_sql))

    # Pagination
    @records = @records.paginate(page: params[:page], per_page: 15)

    render action: :paginated_records
  end

  def filter_by_user_maybe
    @user = params[:user].present? && User.find_by_id(params[:user])
    if @user
      case action_name
      when 'users'
        @records = @records.where(id: @user.id)
        @title = "#{@user.username_or_email}'s Details"
      else
        @records = @records.where(user: @user)
        @title = "#{@user.username_or_email}'s #{@title}"
      end
    end
  end

  def enable_chart_js
    @need_chart_js = true
  end
end
