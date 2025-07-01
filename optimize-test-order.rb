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
    si = at(i)['scenarios']
    sj = at(j)['scenarios']
    apply = sj - si
    retract = si - sj
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
      parser.on('--concorde', 'use concorde solver')
    end.parse!(into: @options)

    raise 'missing cost map' unless (cost_map_file = @options['cost-map'.to_sym])

    log(Logger::INFO, "loading cost map")
    cost_map = JSON.parse(File.read(cost_map_file))['scenarios']
    log(Logger::INFO, "loaded #{cost_map.length} cost map entries")

    tests = JSON.parse(ARGF.read)
    path = TestCircuit.new(@options[:resort] ? tests.sort_by { rand } : tests, cost_map)

    tsp = TSP::TSP_2opt.new(path)
    log(Logger::INFO, "initial order path length: #{tsp.length}")

    if @options[:optimize]
      if @options[:concorde]
        require 'concorde'
        require 'tsplib'
        concorde_spec = TSPLIB::TSP.new('tests', 'tests', tests.length + 1)
        0.upto(concorde_spec.dimension - 1) do |i|
          0.upto(i) do |j|
            concorde_spec.weight[i][j] = path.distance(i, j)
          end
        end
        concorde = Concorde.new(concorde_spec)
        order = concorde.run
        log(Logger::INFO, "result length: #{order.length}")
        result = TSP::TSP_2opt.new(TestCircuit.new(order.drop(1).map { |i| path[i] }, cost_map))
      else
        result = tsp.optimize
      end
    else
      result = tsp
    end

    log(Logger::INFO, "optimized order path length: #{result.length}")

    opt_tests = []
    test_count = 0
    while (pair = result.path.take(2)).length == 2 do
      retract = pair[0]['scenarios'] - pair[1]['scenarios']
      apply = pair[1]['scenarios'] - pair[0]['scenarios']
      opt_tests << pair[1].merge(
        'id' => test_count += 1,
        'scenarios' => pair[1]['scenarios'].to_a.sort,
        'retract' => retract.to_a.sort,
        'apply' => apply.to_a.sort
      )
      result.path.shift
    end
    log(Logger::INFO, "emitting #{opt_tests.length} test configurations")
    puts JSON.pretty_generate({length: result.length, tests: opt_tests})
    0
  end

end

OptimizeTestOrder.new.start
