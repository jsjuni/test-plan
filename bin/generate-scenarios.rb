# frozen_string_literal: true

require 'logger/application'
require 'json'
require 'optparse'

class GenerateScenarios < Logger::Application

  def initialize
    super('generate-scenarios')
  end

  def run
    options = { number: 50 }
    OptionParser.new do |opts|
      opts.banner = "Usage: generate-requirements.rb [options]"
      opts.on('-n NUMBER', '--number NUMBER', Integer, 'number of scenarios (default 50)')
      opts.on('-p NUMBER', '--proxies NUMBER', Integer, 'number of proxies (default 6)')
      opts.on('-c NUMBER', '--cost-max NUMBER', Integer, 'maximum cost (default 20)')
      opts.on('--seed SEED', Integer, 'RNG seed')
    end.parse!(into: options)

    srand(seed = options[:seed] ? seed : 0)
    scenarios = []
    1.upto(options[:number]).each do |s_ord|
      scenarios << {
        id: "S.#{s_ord}",
        cost: (rand * options['cost-max'.to_sym]).to_i + 1
      }
    end
    proxies = []
    1.upto(options[:proxies]).each do |p_ord|
      proxies << {
        id: "PS.#{p_ord}",
        cost: (rand * options['cost-max'.to_sym]).to_i + 1
      }
    end
    result = { scenarios: scenarios, proxies: proxies }
    puts JSON.pretty_generate(result)
  end

  0
end

GenerateScenarios.new.start
