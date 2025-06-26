# frozen_string_literal: true

require 'logger/application'
require 'json'
require 'optparse'

class GenerateCosts < Logger::Application

  def initialize
    super('generate-costs')
    logger.level = Logger::INFO
  end

  def run

    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: generate-costs.rb [options]"
      opts.on('-q QUANTITIES', '--quantities QUANTITIES', 'quantities JSON file')
      opts.on('-s SCENARIOS', '--scenarios SCENARIOS', 'scenarios JSON file')
    end.parse!(into: options)

    raise 'no quantities file' unless options[:quantities]
    raise 'no scenarios file' unless options[:scenarios]

    quantities = JSON.parse(File.open(options[:quantities], 'r').read)
    scenarios = JSON.parse(File.open(options[:scenarios], 'r').read)

    o_cost = {}
    s_cost = {}

    quantities.each do |q|
      o_cost[q['id']] = q['cost']
    end

    scenarios.each_value do |s|
      s.each do |p|
        s_cost[p['id']] = p['cost']
      end
    end

    puts JSON.pretty_generate({ scenarios: s_cost, observations: o_cost })

    0
  end
end

GenerateCosts.new.start


