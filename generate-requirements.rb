# frozen_string_literal: true

require 'json'
require 'logger/application'
require 'optparse'

N_REQUIREMENTS = 200.freeze
P_2CONFIG = 0.1.freeze
MAX_SCENARIOS = 5.freeze
QUANTITIES = (1..50).to_a.freeze

class GenerateRequirements < Logger::Application

  def initialize()
    super('generate-requirements')
    @data = { requirements: [] }
  end

  def run

    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: generate-requirements.rb [options]"
      opts.on('-s SCENARIOS', '--scenarios SCENARIOS', 'scenarios JSON file')
    end.parse!(into: options)

    all_scenarios = JSON.parse(File.open(options[:scenarios], 'r').read)['scenarios'].map { |s| s['id'] }

    1.upto(N_REQUIREMENTS).each do |i|
      id = "R.#{i}"
      n_configs = (rand < P_2CONFIG) ? 2 : 1
      configs = 1.upto(n_configs).inject([]) do |cl, c|
        n_scenarios = (1..MAX_SCENARIOS).to_a.sample(1).first
        scenarios = all_scenarios.sample(n_scenarios).sort_by { |s| s.gsub(/[^\d]+/, '\1').to_i }
        cl << {
          scenarios: scenarios
        }
        cl
      end
     quantity = "Q.#{QUANTITIES.sample.to_s}"
      @data[:requirements] << {id: id, configs: configs, quantity: quantity }
   end
    puts JSON.pretty_generate(@data)
    0
  end
end

GenerateRequirements.new.start

