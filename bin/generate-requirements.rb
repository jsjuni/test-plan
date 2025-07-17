# frozen_string_literal: true

require 'json'
require 'logger/application'
require 'optparse'

P_2SITUATION = 0.1.freeze
MAX_SCENARIOS = 5.freeze

class GenerateRequirements < Logger::Application

  def initialize()
    super('generate-requirements')
    @data = { requirements: [] }
  end

  def run

    options = { number: 200 }
    OptionParser.new do |opts|
      opts.banner = "Usage: generate-requirements.rb [options]"
      opts.on('-n NUMBER', '--number NUMBER', Integer, 'number of requirements (default 200)')
      opts.on('-q QUANTITIES', '--quantities QUANTITIES', 'quantities JSON file')
      opts.on('-s SCENARIOS', '--scenarios SCENARIOS', 'scenarios JSON file')
      opts.on('--seed SEED', Integer, 'RNG seed')
    end.parse!(into: options)

    raise 'no quantities file' unless options[:quantities]
    raise 'no scenarios file' unless options[:scenarios]

    all_quantities = JSON.parse(File.open(options[:quantities], 'r').read).map { |s| s['id'] }
    all_scenarios = JSON.parse(File.open(options[:scenarios], 'r').read)['scenarios'].map { |s| s['id'] }

    srand((seed = options[:seed] ? seed : 0))
    1.upto(options[:number]).each do |i|
      id = "R.#{i}"
      n_situations = (rand < P_2SITUATION) ? 2 : 1
      situations = 1.upto(n_situations).inject([]) do |cl, c|
        n_scenarios = (1..MAX_SCENARIOS).to_a.sample(1).first
        scenarios = all_scenarios.sample(n_scenarios).sort_by { |s| s.gsub(/[^\d]+/, '\1').to_i }
        cl << {
          scenarios: scenarios
        }
        cl
      end
     quantity = all_quantities.sample
      @data[:requirements] << {id: id, situations: situations, quantity: quantity }
   end
    puts JSON.pretty_generate(@data)
    0
  end
end

GenerateRequirements.new.start

