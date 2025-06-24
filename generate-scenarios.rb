# frozen_string_literal: true

require 'logger/application'
require 'json'

SCENARIOS = (1..20).to_a.freeze
PROXIES = (1..6).to_a.freeze

class GenerateScenarios < Logger::Application

  def initialize
    super('generate-scenarios')
  end

  def run
    scenarios = []
    SCENARIOS.each do |s_ord|
      scenarios << {
        id: "S.#{s_ord}",
        cost: s_ord
      }
    end
    proxies = []
    PROXIES.each do |p_ord|
      proxies << {
        id: "PS.#{p_ord}",
        cost: 2 * p_ord
      }
    end
    result = { scenarios: scenarios, proxies: proxies }
    puts JSON.pretty_generate(result)
  end

  0
end

GenerateScenarios.new.start
