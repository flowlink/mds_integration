require 'spec_helper'

describe MDS::Services::SubmitOrder do
  subject { described_class.new(sample_credentials) }

  describe '#builder' do
    it 'adds shipping instructions to the XML when present in JSON' do
      xml = subject.builder(sample_shipment).to_xml
      expect( xml ).to match /OrderNotes/
      expect( xml ).to match /MustShipBy/
      expect( xml ).to match /NoShipBefore/
    end
    it 'does not add shipping notes to the XML when absent from JSON' do
      shipment = sample_shipment.except(:shipping_notes, :must_ship_by, :no_ship_before)
      xml = subject.builder( shipment ).to_xml
      expect( xml ).to_not match /OrderNotes/
      expect( xml ).to_not match /MustShipBy/
      expect( xml ).to_not match /NoShipBefore/
    end
    [:shipping_notes, :must_ship_by, :no_ship_before].each do |key|
      it "does not error when #{key} key is missing from JSON" do
        expect{ subject.builder sample_shipment.delete_if {|k| k == key }
        }.to_not raise_exception
      end
      it "does not error when #{key} is blank in JSON" do
        expect{ subject.builder sample_shipment.merge(key => "")
        }.to_not raise_exception
      end
    end
    it "errors when must_ship_by date is invalid" do
      expect{ subject.builder sample_shipment.merge(must_ship_by: "2015-08-51T00:00:00")
      }.to raise_exception("Error setting up shipping instructions: invalid date")
    end
    it "replaces ampersands in shipping instructions" do
      xml = subject.builder(sample_shipment.merge(shipping_notes: "Pick & pack")).to_xml
      expect( xml ).to match /Pick and pack/
    end
    it "errors when shipping_notes are too long" do
      expect{ subject.builder sample_shipment.merge(shipping_notes: "A"*501)
      }.to raise_exception
    end
  end

  describe '#query' do
    it "allows for internation characters" do
      VCR.use_cassette("submit_internation_order") do

      end
    end

    it 'returns a success response' do
      VCR.use_cassette("submit_order_spec_new_order") do
        response = subject.query(sample_shipment("R123456NEW"))

        expect(response.success?).to eq true
        expect(response.message).to match /was received by MDS Fulfillment/
      end
    end

    context 'duplicate order' do
      it 'returns an error response' do
        VCR.use_cassette("submit_order_spec_duplicate_order") do
          response = subject.query(sample_shipment("R123"))

          expect(response.success?).to eq false
          expect(response.message).to match /Cannot insert duplicate key/
        end
      end
    end

    context 'missing totals' do
      it 'uses 0 as value' do
        VCR.use_cassette("submit_order_spec_no_totals") do
          shipment = sample_shipment("R493330123")
          shipment.delete("totals")

          response = subject.query(shipment)

          expect(response.success?).to eq true
          expect(response.message).to match /was received by MDS Fulfillment/
        end
      end
    end

    context 'missing billing_address' do
      it 'uses shipping_address as billing_address' do
        VCR.use_cassette("submit_order_spec_no_billing_address") do
          shipment = sample_shipment("R357790123")
          shipment.delete("billing_address")

          response = subject.query(shipment)
          expect(response.success?).to eq true
          expect(response.message).to match /was received by MDS Fulfillment/
        end
      end
    end
  end
end
