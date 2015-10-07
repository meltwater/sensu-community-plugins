#! /usr/bin/env ruby
#
#   mesos-metrics
#
# DESCRIPTION:
#   This plugin extracts the stats from a mesos master or slave
#
# OUTPUT:
#    metric data
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: rest-client
#   gem: socket
#   gem: json
#
# USAGE:
#   #YELLOW
#
# NOTES:
#
# LICENSE:
#   Copyright 2015, Tom Stockton (tom@stocktons.org.uk)
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/metric/cli'
require 'rest-client'
require 'socket'
require 'json'

class MesosMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :mode,
         description: 'master or slave',
         short: '-m MODE',
         long: '--mode MODE',
         required: true

  option :scheme,
         description: 'Metric naming scheme',
         short: '-s SCHEME',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.mesos"

  option :server,
         description: 'Mesos Host',
         short: '-h SERVER',
         long: '--host SERVER',
         default: 'localhost'

  option :timeout,
         description: 'timeout in seconds',
         short: '-t TIMEOUT',
         long: '--timeout TIMEOUT',
         proc: proc(&:to_i),
         default: 5

  def run
    uri = '/metrics/snapshot'
    case config[:mode]
    when 'master'
      port = '5050'
    when 'slave'
      port = '5051'
    end
    scheme = "#{config[:scheme]}"
    begin
      r = RestClient::Resource.new("http://#{config[:server]}:#{port}#{uri}", timeout: config[:timeout]).get
      metrics = JSON.parse(r)

      if metrics.fetch("master/elected", 1) != 0
        metrics.each do |k, v|
          k_copy = k.tr('/', '.')
          output([scheme, k_copy].join('.'), v)
        end
      end
    rescue Errno::ECONNREFUSED
      critical "Mesos #{config[:mode]} is not responding"
    rescue RestClient::RequestTimeout
      critical "Mesos #{config[:mode]} Connection timed out"
    end
    ok
  end
end
