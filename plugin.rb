# name: plugin-check-email
# about:  A password validator using Key free disposable email API
# version: 0.0.1
# authors: Terrapop

require 'net/http'
require 'json'

enabled_site_setting :plugin_check_email_enabled

after_initialize do
  module ::DiscoursePluginCheckEmail

    class EmailValidator < ActiveModel::EachValidator

        def validate_each(record, attribute, value)
            return unless record.should_validate_email_address?
            if email_checker(value)
              record.errors.add(attribute, :disposable)
            end
        end

        def valid_json?(json)
              result = JSON.parse(json)
              result.is_a?(Hash) || result.is_a?(Array)
            rescue JSON::ParserError, TypeError
              return false
        end

        def email_checker(email)
            uri = URI(SiteSetting.plugin_check_email_api_url+email)
            response = Net::HTTP.get(uri)
            if valid_json?(response)
                parsed_json = JSON.parse(response)
                if parsed_json['disposable'].nil?
                    Rails.logger.warn("Check email plugin: Json response does not contain key 'disposable'")
                    return true
                else
                    return parsed_json['disposable']
                end
            else
                Rails.logger.warn("Check email plugin: No valid json response, check your API endpoint")
                return true
            end
        end
    end

    class ::User
      validate :plugin_check_email
      def plugin_check_email
        DiscoursePluginCheckEmail::EmailValidator.new(attributes: :email).validate_each(self, :email, email)
      end
    end
  end
end