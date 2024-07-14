module SiteHistory
  extend ActiveSupport::Concern

  included do
    before_action :require_site_history_or_preview_enabled!,
      only: [:history]

    before_action :require_site_history_enabled!,
      only: [:view_version, :download_version, :restore_version, :discard_version]

    before_action :set_blob_id,
      only: [:view_version, :download_version, :restore_version, :discard_version,
        :version_label_form, :version_label_update]

    before_action :set_attachment,
      only: [:version_label_form, :version_label_update]

    # Avoid this error when doing the js format get in test/controllers/sites_controller_test.rb
    #   ActionController::InvalidCrossOriginRequest: Security warning: an embedded
    #   <script> tag on another site requested protected JavaScript.
    # Beware: Unexpectedly we can't use 'only' and 'if' together here, see the details at
    # https://github.com/rails/rails/issues/9703. That's why action_name is checked like this.
    skip_before_action :verify_authenticity_token,
      if: -> { Rails.env.test? && action_name == 'version_label_form' }
  end

  def history
    @current_blob_id = @site.blob.id
    @saved_version_count = @site.saved_version_count
    @keep_count = @site.keep_count
  end

  def view_version
    # (Not sure what's best for is_logged_in here but it probably doesn't matter much)
    render html: @site.html_content_for_blob_id(@blob_id, is_logged_in: true).html_safe
  end

  # Make the favicon request work. Needed because TiddlyWiki uses a relative link to
  # the favicon file by default
  def view_version_favicon
    send_favicon(@site.favicon_asset_name)
  end

  def download_version
    download_html_content(@site.download_content_for_blob_id(@blob_id), @site.name)
  end

  def restore_version
    @site.content_upload(@site.file_download(@blob_id))
    redirect_to action: :history
  end

  def discard_version
    # It's not generally recommended to purge blobs in the foreground in case the
    # back end is flaky or slow, but let's try this anyway and see how it goes.
    @site.specific_saved_content_file(@blob_id).purge
    redirect_to action: :history
  end

  # Expected to be accessed with an ajax style request
  def version_label_form
    respond_to do |format|
      format.js do
        # It will find the version_label_form partial automagically
        render partial: 'modal_open'
      end
    end
  end

  # Expected to be a "patch" request
  def version_label_update
    new_label = params.dig(:attachment, :attachment_label).presence
    current_label = @attachment.attachment_label
    @attachment.attachment_label = new_label if new_label != current_label
    redirect_to history_site_path(@site)
  end

  private

  def require_site_history_or_preview_enabled!
    require_condition!(feature_enabled?(:site_history) || feature_enabled?(:site_history_preview))
  end

  def require_site_history_enabled!
    require_condition!(feature_enabled?(:site_history))
  end

  def set_blob_id
    @blob_id = params[:blob_id]
  end

  # Could maybe use the attachment id as the param and change the routing
  # accordingly, but for now use the blob id everywhere to be consistent
  def set_attachment
    @attachment = @site.specific_saved_content_file(@blob_id)
  end
end
