require 'active_support/core_ext/hash'

module MDS
  module Services
    module Base
      def self.included(base)
        base.send(:extend, ClassMethods)
      end

      module ClassMethods
        attr_reader :url_package, :xml_root

        def set_url_package(package)
          @url_package = package
        end

        def set_xml_root(xml_root)
          @xml_root = xml_root
        end
      end

      def initialize(credentials)
        credentials[:client_code] ||= ENV['MDS_CLIENT_CODE'] if ENV['MDS_CLIENT_CODE'].present?
        credentials[:client_signature] ||= ENV['MDS_CLIENT_SIGNATURE'] if ENV['MDS_CLIENT_SIGNATURE'].present?
        credentials[:test_mode] ||= ENV['MDS_TEST_MODE'] if ENV['MDS_TEST_MODE'].present?
        credentials[:debug_mode] ||= ENV['MDS_DEBUG_MODE'] if ENV['MDS_DEBUG_MODE'].present?

        @client_code = credentials.fetch(:client_code)
        @client_signature = credentials.fetch(:client_signature)
        @test_mode = credentials.fetch(:test_mode, "1")
        @debug_mode = credentials.fetch(:debug_mode, nil) || @test_mode
      end

      def query(object = {})
        payload = builder(object).to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
        xml_response = HTTParty.get(
          "#{mds_url}/#{self.class.url_package}/ReceiveXML.aspx?xml=" + URI.encode(payload),
          debug_output: @debug_mode == '1' ? $stdout : nil
        )
        build_response_instance(xml_response)
      end

      def build_response_instance(xml_response)
        response = Hash.from_xml(xml_response)
        klass    = response.keys[0]
        body     = response[klass]

        MDS::Responses.const_get(klass).new(body)
      end

      def xml_builder
        Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
          xml.send(self.class.xml_root, 'xml:lang' => 'en-US') do
            xml.ClientCode @client_code
            xml.ClientSignature @client_signature
            yield(xml)
          end
        end
      end

      def mds_url
        @test_mode == "1" ?
          "http://webservice-dev.mdsfulfillment.com" :
          "https://webservice.mdsfulfillment.com"
      end
    end
  end
end