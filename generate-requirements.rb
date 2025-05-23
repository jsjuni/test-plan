# frozen_string_literal: true

require 'json'
require 'logger/application'

N_REQUIREMENTS = 200.freeze
SCENARIOS = (1..20).to_a.freeze
MAX_SCENARIOS = 5.freeze
QUANTITIES = (1..50).to_a.freeze

class GenerateRequirements < Logger::Application

  def initialize()
    super('generate-requirements')
    @data = { requirements: [] }
  end

  def run
    1.upto(N_REQUIREMENTS).each do |id|
      n_scenarios = (1..MAX_SCENARIOS).to_a.sample(1).first
      scenarios = SCENARIOS.sample(n_scenarios).sort
      quantity = QUANTITIES.sample
      @data[:requirements] << {id: id, scenarios: scenarios, quantity: quantity }
   end
    puts JSON.pretty_generate(@data)
    0
  end
end

GenerateRequirements.new.start

