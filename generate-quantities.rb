# frozen_string_literal: true

require 'logger/application'
require 'json'

QUANTITIES = (1..50).to_a.freeze
COST_MAX = 10

class GenerateQuantities < Logger::Application

  def initialize
    super('generate-quantities')
  end

  srand(0)
  def run
    quantities = []
    QUANTITIES.each do |q_ord|
      quantities << {
        id: "Q.#{q_ord}",
        cost: (rand * COST_MAX).to_i + 1
      }
    end

    puts JSON.pretty_generate(quantities)
  end

  0
end

GenerateQuantities.new.start
