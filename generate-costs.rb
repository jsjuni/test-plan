# frozen_string_literal: true

require 'logger/application'
require 'json'

class GenerateCosts < Logger::Application

  def initialize
    super('generate-costs')
    logger.level = Logger::INFO
  end

  def run

    requirements = JSON.parse(ARGF.read)['requirements']
    scenarios = requirements.inject(Set.new) do |s, r|
      s + r['configs'].map { |c| c['scenarios'] }.flatten
    end.sort
    log(Logger::DEBUG, "scenarios #{scenarios}")
    n_scenarios = scenarios.length

    costs_hash = scenarios.inject(Hash.new) do |h, k|
      h[k] = (c = (k.sub(/[^\d]+/, '\1').to_i) % n_scenarios) == 0 ? n_scenarios : c
      h
    end
    puts JSON.pretty_generate(costs_hash)
  end
end

GenerateCosts.new.start


