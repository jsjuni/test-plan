# frozen_string_literal: true

require 'logger/application'
require 'json'
require 'optparse'

class GenerateSufficiency < Logger::Application

  def initialize
    super('generate-sufficiency')
  end

  def prune_configs(mode, max, configs)
    lengths = configs.map { |c| c.length }
    max_length = lengths.max
    min_length = lengths.min
    select = (mode == :least) ? min_length : max_length
    candidates = configs.select { |c| c.length == select }
    (max.nil? || candidates.length <= max) ? candidates : candidates.sample(max)
  end

  def run

    options = {}
    OptionParser.new do |opts|
      opts.banner = 'Usage: generate-sufficiency.rb [options]'
      opts.on('--p-least PROB', Numeric, 'probability of least restrictive sufficiency')
      opts.on('-m MAX', '--max MAX', Integer, 'maximum number of configs')
      opts.on('--seed SEED', Integer, 'RNG seed')
    end.parse!(into: options)

    raise "invalid seed #{options[:seed]}" if options[:seed] && !options[:seed].is_a?(Integer)

    p_least = options['p-least'.to_sym]
    raise "missing p_least" unless p_least
    raise "invalid p_least #{p_least}" if p_least < 0.0 || p_least > 1.0

    data = JSON.parse(ARGF.read)

    srand(options[:seed]) if options[:seed]
    data.each do |rh|
      mode = rand < p_least ? :least : :most
      rh['configs'] = prune_configs(mode, options[:max], rh['configs'])
    end

    puts JSON.pretty_generate(data)

    0
  end

end

GenerateSufficiency.new.start