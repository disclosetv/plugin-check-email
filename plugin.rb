# name: plugin-check-email
# about: An email validator using API
# version: 0.0.1
# authors: terrapop

require 'net/http'

enabled_site_setting :plugin_check_email_enabled

after_initialize do
  module ::DiscoursePluginCheckEmail

    class EmailValidator < ActiveModel::EachValidator

        def validate_each(record, attribute, value)
            return unless record.should_validate_email_address?
            if email_checker(value)
              record.errors.add(attribute, "is not allowed from that email provider! Please use another one.")
            end
        end

        def email_checker(email)
            uri = URI(SiteSetting.plugin_check_email_api_url+email)
            result = Net::HTTP.get(uri)
            is_invalid = false
            if result == "invalid"
                is_invalid = true
                else
                is_invalid = false
            end
            return is_invalid
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