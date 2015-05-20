module MDS
  module Services
    module ShippingStatus
      class Tracking
        include Base

        set_xml_root    'MDSShippingTracking'
        set_url_package 'mds.shipping.Tracking'

        def initialize(config)
          super

          @number_of_days = config[:number_of_days] || 2
        end

        def builder(_)
          xml_builder do |xml|
            xml.Days @number_of_days.to_s
          end
        end
      end
    end
  end
end
