# frozen_string_literal: true

require 'logger/application'
require 'json'

SCENARIOS = (1..20).to_a.freeze
PROXIES = (1..6).to_a.freeze
COST_MAX = 20

class GenerateScenarios < Logger::Application

  def initialize
    super('generate-scenarios')
  end

  def run
    srand(0)
    scenarios = []
    SCENARIOS.each do |s_ord|
      scenarios << {
        id: "S.#{s_ord}",
        cost: (rand * COST_MAX).to_i + 1
      }
    end
    proxies = []
    PROXIES.each do |p_ord|
      proxies << {
        id: "PS.#{p_ord}",
        cost: (rand * COST_MAX).to_i + 1
      }
    end
    result = { scenarios: scenarios, proxies: proxies }
    puts JSON.pretty_generate(result)
  end

  0
end

GenerateScenarios.new.start
