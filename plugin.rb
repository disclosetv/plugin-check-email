# name: plugin-check-email
# about:  A password validator using Key free disposable email API
# version: 0.0.1
# authors: Terrapop

require 'net/http'

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

        def email_checker(email)
            uri = URI(SiteSetting.plugin_check_email_api_url+email)
            response = Net::HTTP.get(uri)
            parsed_json = JSON.parse(response)
            return parsed_json['disposable']
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