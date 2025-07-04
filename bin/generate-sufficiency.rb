# frozen_string_literal: true

require 'logger/application'
require 'json'
require 'optparse'
require 'rgl/bidirectional_adjacency'

class GenerateSufficiency < Logger::Application

  def initialize
    super('generate-sufficiency')
  end

  def prune_configs(mode, max, configs)
    graph = configs.sort_by { |c| c.length }.map { |c| c.to_set }.inject(RGL::BidirectionalAdjacencyGraph.new) do |g, config|
      subs = g.vertices.inject([]) do |sa, c|
        sa << c if c < config
        sa
      end
      g.add_vertex(config)
      subs.each { |sub| g.add_edge(sub, config)}
      g
    end
    degree = (mode == :least) ? :in_degree : :out_degree
    candidates = graph.vertices.select { |config| graph.method(degree).call(config) == 0 }.map { |c| c.to_a }
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