##
## Handle events and sends them to BigPanda API.
##
## If you have the template, you should set the TOKEN placeholder (in curly brackets) to your organization token.
## More details at https://a.bigpanda.io/#/app/integrations/sensu/instructions (you must login first)
##
## This is an edit of BigPanda's official sensu handler made into an extension
##
## The benefit to an extension is sensu won't fork a new process for each even it has to send
## to BigPanda. The resulting forking can add excess load to the server.
##
## Extension Author: Mike Zupan <mike@zcentric.com> @mikezupan
## Author: BigPanda <support@bigpanda.io>
## License: The same as Sensu original license (MIT); see LICENSE for details.
##


require 'json'
require 'net/http'

module Sensu::Extension

  class BigPanda < Handler

    def post_init
    end

    def definition
      {
        type: 'extension',
        name: 'bigpanda',
        mutator: 'ruby_hash',
      }
    end

    def name
      definition[:name]
    end

    def description
      'A BigPanda.io extension so sensu will not fork'
    end


    def run(event_data)
      begin
        headers  = { 'Accept' => 'application/json',
                     'Content-Type' => 'application/json' }

        uri = URI.parse('https://api.bigpanda.io/')
        h = Net::HTTP.new uri.host, uri.port
        h.use_ssl = (uri.scheme.downcase == 'https')

        h.start do |http|
          response = http.post '/data/integrations/sensu?access_token=' + settings['bigpanda']['token'], JSON.generate(event_data), headers
          if response.code.to_i < 300
            yield("Called BigPanda.io for client: #{event_data[:client][:name]} check: #{event_data[:check][:name]}", 0)
          else
            yield("Failure while trying to call BigPanda API for client: #{event_data[:client][:name]} check: #{event_data[:check][:name]} message: #{response.message}", 2)
          end
        end
      rescue Timeout::Error
        yield("Timeout while trying to call BigPanda API for client: #{event_data[:client][:name]} check: #{event_data[:check][:name]}", 2)
      end
    end

    def stop
      yield
    end

  end
end
