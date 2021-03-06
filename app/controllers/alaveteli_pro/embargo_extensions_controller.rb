# -*- encoding : utf-8 -*-
# app/controllers/alaveteli_pro/embargo_extensions_controller.rb
# Controller for embargo extensions
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AlaveteliPro::EmbargoExtensionsController < AlaveteliPro::BaseController
  def create
    @embargo = AlaveteliPro::Embargo.find(embargo_extension_params[:embargo_id])
    authorize! :update, @embargo
    @info_request = @embargo.info_request
    @embargo_extension = AlaveteliPro::EmbargoExtension.new(embargo_extension_params)
    if @embargo_extension.save
      @embargo.extend(@embargo_extension)
      flash[:notice] = _("Your request will now be private on " \
                         "{{site_name}} until {{expiry_date}}.",
                         site_name: AlaveteliConfiguration.site_name,
                         expiry_date: I18n.l(@embargo.publish_at, format: '%d %B %Y'))
    else
      flash[:error] = _("Sorry, something went wrong updating your " \
                        "request's privacy settings, please try again.")
    end
    redirect_to show_alaveteli_pro_request_path(
        url_title: @info_request.url_title)
  end

  private

  def embargo_extension_params
    params.require(:alaveteli_pro_embargo_extension).permit(:embargo_id, :extension_duration)
  end
end
