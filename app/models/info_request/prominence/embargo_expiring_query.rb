# -*- encoding : utf-8 -*-
class InfoRequest
  module Prominence
    class EmbargoExpiringQuery
      def initialize(relation = InfoRequest)
        @relation = relation
      end

      def call
        @relation.includes(:embargo)
          .where('embargoes.id IS NOT NULL')
            .where("embargoes.expiring_notifiction_at <= ?", Time.zone.now)
              .references(:embargoes)
      end
    end
  end
end
