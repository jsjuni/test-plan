# frozen_string_literal: true

require 'logger/application'
require 'json'
require 'optparse'

class GenerateQuantities < Logger::Application

  def initialize
    super('generate-quantities')
  end

  def run
    options = { number: 50 }
    OptionParser.new do |opts|
      opts.banner = "Usage: generate-requirements.rb [options]"
      opts.on('-n NUMBER', '--number NUMBER', Integer, 'number of quantities (default 50)')
      opts.on('-c NUMBER', '--cost-max NUMBER', Integer, 'maximum cost (default 10)')
      opts.on('--seed SEED', Integer, 'RNG seed')
    end.parse!(into: options)

    srand(seed = options[:seed] ? seed : 0)
    quantities = []
    1.upto(options[:number]).each do |q_ord|
      quantities << {
        id: "Q.#{q_ord}",
        cost: (rand * options['cost-max'.to_sym]).to_i + 1
      }
    end

    puts JSON.pretty_generate(quantities)
  end

  0
end

GenerateQuantities.new.start
