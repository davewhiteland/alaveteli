# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: request_summaries
#
#  id                 :integer          not null, primary key
#  title              :text
#  body               :text
#  public_body_names  :text
#  summarisable_id    :integer          not null
#  summarisable_type  :string(255)      not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_id            :integer
#  request_created_at :datetime         default(2017-06-05 09:19:11 UTC), not null
#  request_updated_at :datetime         default(2017-06-05 09:19:11 UTC), not null
#

class AlaveteliPro::RequestSummary < ActiveRecord::Base
  belongs_to :summarisable, polymorphic: true
  belongs_to :user
  has_and_belongs_to_many :request_summary_categories,
                          :class_name => "AlaveteliPro::RequestSummaryCategory"

  validates_presence_of :summarisable

  ALLOWED_REQUEST_CLASSES = ["InfoRequest",
                             "DraftInfoRequest",
                             "InfoRequestBatch",
                             "AlaveteliPro::DraftInfoRequestBatch"].freeze

  def self.category(category_slug)
    includes(:request_summary_categories).
      where("request_summary_categories.slug = ?", category_slug.to_s).
        references(:request_summary_categories)
  end

  def self.not_category(category_slug)
    summary_ids_to_exclude = self.category(category_slug).pluck(:id)
    results = includes(:request_summary_categories)
    unless summary_ids_to_exclude.blank?
      results = results.
        where("request_summaries.id NOT IN (?)", summary_ids_to_exclude)
    end
    results
  end

  def self.create_or_update_from(request)
    unless ALLOWED_REQUEST_CLASSES.include?(request.class.name)
      raise ArgumentError.new("Can't create a RequestSummary from " \
                              "#{request.class.name} instances. Only " \
                              "#{ALLOWED_REQUEST_CLASSES} are allowed.")
    end
    if request.request_summary
      request.request_summary.update_from_request
      request.request_summary
    else
      self.create_from(request)
    end
  end

  def update_from_request
    update_attributes(self.class.attributes_from_request(self.summarisable))
  end

  private

  def self.create_from(request)
    self.create(attributes_from_request(request))
  end

  def self.attributes_from_request(request)
    {
      title: request.title,
      body: request.request_summary_body,
      public_body_names: request.request_summary_public_body_names,
      summarisable: request,
      user: request.user,
      request_summary_categories: request.request_summary_categories,
      request_created_at: request.created_at,
      request_updated_at: request.updated_at,
    }
  end
end
