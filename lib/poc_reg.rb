# Copyright (C) 2011 American Registry for Internet Numbers

require 'erb'
require 'yaml'
require 'rexml/document'
require 'utils'

module ARINr

  module Registration

    # basic holder POC registration information
    class Poc
      attr_accessor :handle, :type, :last_name, :first_name, :middle_name, :company_name
      attr_accessor :street_address, :city, :state, :country, :postal_code
      attr_accessor :phones, :emails, :comments

      def get_binding
        return binding
      end
    end

    # Takes a POC and returns a string full of YAML goodness
    def Registration::poc_to_template poc
      template = ""
      file = File.new( File.join( File.dirname( __FILE__ ), "poc_template.yaml" ), "r" )
      file.each_line do |line|
        template << line
      end
      file.close

      yaml = ERB.new( template, 0, "<>" )
      return yaml.result( poc.get_binding )
    end

    # Takes a string containing YAML and converts it to a POC
    def Registration::yaml_to_poc yaml_str
      struct = YAML.load( yaml_str )
      poc = ARINr::Registration::Poc.new
      poc.handle=struct[ "handle" ]
      poc.type=struct[ "type" ]
      poc.last_name=struct[ "last name" ]
      poc.first_name=struct[ "first name" ]
      poc.middle_name=struct[ "middle name" ]
      poc.company_name=struct[ "company name" ]
      poc.street_address=struct[ "address" ]
      poc.city=struct[ "city" ]
      poc.state=struct[ "state or province" ]
      poc.country=struct[ "country" ]
      poc.postal_code=struct[ "postal or zip code" ]
      poc.phones=struct[ "phones" ]
      poc.emails=struct[ "email addresses" ]
      poc.comments=struct[ "public comments" ]
      return poc
    end

    # Takes a poc and creates XML
    def Registration::poc_to_element poc
      element = REXML::Element.new( "poc" )
      element.add_namespace( "http://www.arin.net/regrws/core/v1" )
      element.add_attribute( ARINr::new_element_with_text( "iso3166-2", poc.state.to_s ) )
      iso3166_1 = REXML::Element.new( "iso3166-1" )
      iso3166_1.add_element( ARINr::new_element_with_text( "code2", poc.country.to_s ) )
      element.add_element( iso3166_1 )
      element.add_element( ARINr::new_wrapped_element( "emails", "email", poc.emails ) )
      element.add_element( ARINr::new_number_wrapped_element( "streetAddress", poc.street_address ) )
      element.add_element( ARINr::new_element_with_text( "city", poc.city ) )
      element.add_element( ARINr::new_element_with_text( "postalCode", poc.postal_code ) )
      element.add_element( ARINr::new_number_wrapped_element( "comment", poc.comments ) )
      element.add_element( ARINr::new_element_with_text( "contactType", poc.type ) )
      element.add_element( ARINr::new_element_with_text( "companyName", poc.company_name ) )
      element.add_element( ARINr::new_element_with_text( "firstName", poc.first_name ) )
      element.add_element( ARINr::new_element_with_text( "middleName", poc.middle_name ) )
      element.add_element( ARINr::new_element_with_text( "lastName", poc.last_name ) )
      phones = REXML::Element.new( "phones" )
      element.add_element( phones )
      poc.phones.each do |k,v|
        phone = REXML::Element.new( "phone" )
        type = REXML::Element.new( "type" )
        case k
          when /office/i
            type.add_element( ARINr::new_element_with_text( "code", "O" ) )
          when /mobile/i
            type.add_element( ARINr::new_element_with_text( "code", "M" ) )
          when /fax/i
            type.add_element( ARINr::new_element_with_text( "code", "F" ) )
        end
        phone.add_element( type )
        phone.add_element( ARINr::new_element_with_text( "number", v[ 0 ] ) )
        phone.add_element( ARINr::new_element_with_text( "extension", v[ 0 ] ) ) if v[ 1 ]
        phones.add_element( phone )
      end
      element.add_element( ARINr::new_element_with_text( "handle", poc.handle ) )
      return element
    end

    def Registration::element_to_poc element
      poc = ARINr::Registration::Poc.new
      poc.state=element.elements[ "iso3166-2" ][ 0 ].text
      poc.country=element.elements[ "iso3166-1/code2" ][ 0 ].text
      poc.emails=[]
      element.elements[ "emails/email" ].each do |email|
        poc.emails << email.text
      end
      poc.street_address=[]
      element.elements[ "streetAddress/line" ].each do |line|
        poc.street_address << line.text
      end
      poc.city=element.elements[ "city" ][ 0 ].text
      poc.postal_code=element.elements[ "postalCode" ][ 0 ].text
      poc.comments=[]
      element.elements[ "comment/line" ].each do |line|
        poc.comments << line
      end
      poc.type=element.elements[ "contactType" ][ 0 ].text
      poc.company_name=element.elements[ "companyName" ][ 0 ].text
      poc.first_name=element.elements[ "firstName" ][ 0 ].text
      poc.last_name=element.elements[ "lastName" ][ 0 ].text
      poc.middle_name=element.elements[ "middle_name" ][ 0 ].text
      poc.phones={}
      element.elements[ "phones/phone" ].each do |phone|
        number = []
        number << phone.elements[ "number" ].text
        number << phone.elements[ "extension" ].text if phone.elements[ "extension" ]
        type = phone.elements[ "type" ]
        case type.text
          when "O"
            poc.phones[ "office" ] = number
          when "M"
            poc.phones[ "mobile" ] = number
          when "F"
            poc.phones[ "fax" ] = number
        end
      end
      return poc
    end

  end

end
