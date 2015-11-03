#!/usr/bin/env ruby

#
# Handle events and sends them to BigPanda API.
#
# If you have the template, you should set the TOKEN placeholder (in curly brackets) to your organization token.
# More details at https://a.bigpanda.io/#/app/integrations/sensu/instructions (you must login first)
#
# Author: BigPanda <support@bigpanda.io>
# License: The same as Sensu original license (MIT); see LICENSE for details.
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-handler'
require 'json'
require 'net/http'

class Slack < Sensu::Handler
  def handle
    begin
      headers  = { 'Accept' => 'application/json',
                   'Content-Type' => 'application/json' }

      uri = URI.parse('https://api.bigpanda.io/')
      h = Net::HTTP.new uri.host, uri.port
      h.use_ssl = (uri.scheme.downcase == 'https')

      h.start do |http|
        appKeyString = ''
        if (defined?(settings['bigpanda']['app_key']) && (settings['bigpanda']['app_key'] != ''))
          appKeyString = '&app_key=' + settings['bigpanda']['app_key']
        end
        response = http.post '/data/integrations/sensu?access_token=' + settings['bigpanda']['token'] + appKeyString, JSON.generate(@event), headers

        if response.code.to_i < 300
          puts 'Called BigPanda API for client: ' + @event['client']['name'] + ' check: ' + @event['check']['name']
        else
          puts 'Failure while trying to call BigPanda API for client: ' + @event['client']['name'] + ' check: ' + @event['check']['name'] + ' message: ' + response.message
        end
      end
    rescue Timeout::Error
      puts 'Timeout while trying to call BigPanda API for client: ' + @event['client']['name'] + ' check: ' + @event['check']['name']
    end
  end
end
