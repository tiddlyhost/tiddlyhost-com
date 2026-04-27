class CustomDomainsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_site
  before_action -> { require_feature_enabled!(:custom_domains) }

  def show
    @custom_domain = @site.custom_domain || @site.build_custom_domain
  end

  def create
    @custom_domain = @site.build_custom_domain(custom_domain_params)
    if @custom_domain.save
      redirect_to site_custom_domain_path(@site)
    else
      render :show
    end
  end

  def destroy
    @site.custom_domain&.destroy
    redirect_to site_custom_domain_path(@site)
  end

  def verify
    @site.custom_domain&.verify_now!
    redirect_to site_custom_domain_path(@site)
  end

  private

  def set_site
    @site = current_user.sites.find(params[:site_id])
  end

  def custom_domain_params
    params.require(:custom_domain).permit(:domain)
  end
end
