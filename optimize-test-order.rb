# frozen_string_literal: true

require 'json'
require 'logger/application'
require 'rgl/adjacency'
require 'rgl/transitivity'
require 'TSP_2opt'
require 'optparse'

class TestCircuit < TSP::Path

  def initialize(array, cost_map)
    @cost_map = cost_map
    a = array.dup.unshift({ 'id' => 0, 'scenarios' => [] })
    super(a)
  end

  def distance(i, j)
    apply = at(j)['scenarios'] - at(i)['scenarios']
    retract = at(i)['scenarios'] - at(j)['scenarios']
    (apply + retract).inject(0) { |s, e| s + @cost_map[e.to_s] }
  end

end

class OptimizeTestOrder < Logger::Application

  def initialize
    super('optimize-test-order')

    logger.level = Logger::INFO
  end

  def run

    @options = {optimize: true}
    OptionParser.new(:req) do |parser|
      parser.on('-c MAP', '--cost-map MAP', 'cost map')
      parser.on('--[no-]optimize', 'optimize test order')
      parser.on('-r', '--resort', 'resort test order randomly')
    end.parse!(into: @options)

    raise 'missing cost map' unless (cost_map_file = @options['cost-map'.to_sym])

    log(Logger::INFO, "loading cost map")
    cost_map = JSON.parse(File.read(cost_map_file))
    log(Logger::INFO, "loaded #{cost_map.length} cost map entries")

    tests = JSON.parse(ARGF.read)
    path = TestCircuit.new(@options[:resort] ? tests.sort_by { rand } : tests, cost_map)
    tsp = TSP::TSP_2opt.new(path)
    log(Logger::INFO, "initial order path length: #{tsp.length}")
    tsp.optimize if @options[:optimize]
    log(Logger::INFO, "optimized order path length: #{tsp.length}")

    opt_tests = []
    while (pair = tsp.path.take(2)).length == 2 do
      retract = pair[0]['scenarios'] - pair[1]['scenarios']
      apply = pair[1]['scenarios'] - pair[0]['scenarios']
      opt_tests << pair[1].merge(
        'scenarios' => pair[1]['scenarios'].to_a.sort,
        'retract' => retract.to_a.sort,
        'apply' => apply.to_a.sort
      )
      tsp.path.shift
    end
    log(Logger::INFO, "emitting #{opt_tests.length} test configurations")
    puts JSON.pretty_generate({length: tsp.length, tests: opt_tests})
    0
  end

end

OptimizeTestOrder.new.start
