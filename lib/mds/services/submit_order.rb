module MDS
  module Services
    class SubmitOrder
      include Base

      set_xml_root    'MDSOrder'
      set_url_package 'mds.order'
      
      def builder(shipment)
        xml_builder do |xml|
          fix_encoding(shipment[:shipping_address][:company])

          ship_name = "#{shipment[:shipping_address][:firstname]} #{shipment[:shipping_address][:lastname]}"
          fix_encoding(ship_name)

          xml.Order do
            xml.OrderID         shipment[:id]
            xml.ConsumerPONum   shipment[:id]
            xml.OrderDate       DateTime.parse(shipment[:placed_on]).strftime('%F %R')
            xml.ShippingMethod  shipment[:shipping_method]
            xml.Shipname        ship_name
            xml.ShipCompany     shipment[:shipping_address][:company]
            xml.ShipAddress1    shipment[:shipping_address][:address1]
            xml.ShipAddress2    shipment[:shipping_address][:address2]
            xml.ShipCity        shipment[:shipping_address][:city]
            xml.ShipState       shipment[:shipping_address][:state]
            xml.ShipCountry     shipment[:shipping_address][:country]
            xml.ShipZip         shipment[:shipping_address][:zipcode]
            xml.ShipEmail       shipment[:email]
            xml.ShipPhone       shipment[:shipping_address][:phone]

            setup_shipping_instructions(xml, shipment)
            setup_billing_information(xml, shipment)

            xml.CSEmail         shipment[:email]
            xml.CSPhone         shipment[:shipping_address][:phone]

            setup_totals(xml, shipment[:totals])

            xml.Lines do
              build_products(xml, shipment)
            end
          end
        end
      end

      def setup_shipping_instructions(xml, shipment)
        mds_format = "%m/%d/%Y"
        if shipment[:shipping_notes].present?
          notes = shipment[:shipping_notes].gsub("&", "and")
          raise "shipping_notes max length exceeded" if notes.length > 255
          xml.OrderNotes      notes
        end
        if shipment[:no_ship_before].present?
          xml.NoShipBefore    Date.parse(shipment[:no_ship_before]).strftime(mds_format)
        end
        if shipment[:must_ship_by].present?
          xml.MustShipBy      Date.parse(shipment[:must_ship_by]).strftime(mds_format)
        end
      rescue => error
        raise "Error setting up shipping instructions: #{error}"
      end

      def build_products(xml, shipment)
        shipment[:items].each_with_index do |line_item, index|
          xml.Line(number: index + 1) do
            xml.RetailerItemID  line_item[:product_id]
            xml.CUSTItemID      line_item[:product_id]
            xml.UPC             line_item[:product_id]
            xml.Qty             line_item[:quantity]
            xml.PricePerUnit    line_item[:price]
          end
        end
      end

      def setup_totals(xml, totals)
        totals = totals || {}

        xml.ShippingCharge  totals[:shipping] || 0
        xml.ShippingTax     totals[:tax]      || 0
        xml.ShippingTotal   totals[:shipping] || 0
      end

      def setup_billing_information(xml, shipment)
        billing_address = shipment[:billing_address] || shipment[:shipping_address]

        bill_name = "#{billing_address[:firstname]} #{billing_address[:lastname]}"
        fix_encoding(bill_name)

        xml.Billname        bill_name
        xml.BillAddress1    billing_address[:address1]
        xml.BillAddress2    billing_address[:address2]
        xml.BillCity        billing_address[:city]
        xml.BillState       billing_address[:state]
        xml.BillCountry     billing_address[:country]
        xml.BillZip         billing_address[:zipcode]
      end

      protected

        # MDS has some strange encoding requirements because of the frameworks they are using
        def fix_encoding(string)
          return if string.blank?

          string.gsub!('&', '%26amp;')
        end
    end
  end
end