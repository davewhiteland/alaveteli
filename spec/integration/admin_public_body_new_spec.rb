# -*- encoding : utf-8 -*-
require 'spec_helper'
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe 'Adding a Public Body' do
  before do
    allow(AlaveteliConfiguration).to receive(:skip_admin_auth).and_return(false)

    confirm(:admin_user)
    @admin = login(:admin_user)
  end

  it 'handles default underscore locales properly' do
    AlaveteliLocalization.set_locales(available_locales='en_GB es',
                                      default_locale='en_GB')
    using_session(@admin) do
      visit new_admin_body_path
      expect(page).
        to have_css('#div-locale-en_GB input[name="public_body[name]"]')
    end
  end

end
