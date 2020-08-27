# name: plugin-check-email
# about: An email validator using API
# version: 0.0.1
# authors: terrapop

# record.errors.add(attribute, I18n.t(:'user.email.not_allowed'))

require 'net/http'

enabled_site_setting :plugin_check_email_enabled

after_initialize do
  module ::DiscoursePluginCheckEmail

    Rails.logger.warn("XXX init")

    class EmailValidator < ActiveModel::EachValidator

        def validate_each(record, attribute, value)
            return unless record.should_validate_email_address?
            if email_checker(value)
              record.errors.add(attribute, "ERROR INVALID")
            end
        end

        def email_checker(email)
            uri = URI(SiteSetting.plugin_check_email_api_url+email)
            Rails.logger.warn("XXX url: #{uri}")
            result = Net::HTTP.get(uri)
            Rails.logger.warn("XXX result: #{result}")
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