# frozen_string_literal: true

require 'logger/application'
require 'json'

class GenerateCosts < Logger::Application

  def initialize
    super('generate-costs')
    logger.level = Logger::INFO
  end

  def run

    input = JSON.parse(ARGF.read)
    s_cost = {}

    input.each_value do |a|
      a.each do |p|
        s_cost[p['id']] = p['cost']
      end
    end

    puts JSON.pretty_generate({ scenarios: s_cost, observations: {} })

    0
  end
end

GenerateCosts.new.start


