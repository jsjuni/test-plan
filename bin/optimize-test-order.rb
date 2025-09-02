# frozen_string_literal: true

require 'json'
require 'logger/application'
require 'rgl/adjacency'
require 'rgl/transitivity'
require 'TSP_2opt'
require 'optparse'

class OptimizeTestOrder < Logger::Application

  def initialize
    super('optimize-test-order')
    logger.level = Logger::INFO
  end

  def make_weights(tests, cost_map)
    0.upto(tests.length - 1).inject([]) do |a, i|
      si = tests[i]['scenarios']
      a << 0.upto(i).map do |j|
        sj = tests[j]['scenarios']
        apply = sj - si
        retract = si - sj
        (apply + retract).inject(0) { |s, e| s + cost_map[e.to_s] }
      end
      a
    end  end

  def run

    @options = {optimize: true}
    OptionParser.new(:req) do |parser|
      parser.on('-c MAP', '--cost-map MAP', 'cost map')
      parser.on('--[no-]optimize', 'optimize test order')
      parser.on('-r', '--resort', 'resort test order randomly')
      parser.on('--concorde', 'use concorde solver')
      parser.on('--tolerance NUMBER', '-t NUMBER', Float, 'termination tolerance for concorde solver')
    end.parse!(into: @options)

    raise 'missing cost map' unless (cost_map_file = @options['cost-map'.to_sym])
    raise '--no-optimize invalid with --concorde' if !@options[:optimize] && @options[:concorde]

    log(Logger::INFO, "loading cost map")
    cost_map = JSON.parse(File.read(cost_map_file))
    log(Logger::INFO, "loaded #{cost_map['observations'].length + cost_map['scenarios'].length} cost map entries")

    t = JSON.parse(ARGF.read)
    tests = (@options[:resort] ? t.sort_by { rand } : t.dup).unshift({ 'id' => 0, 'scenarios' => [], 'quantities' => {} })
    weights = make_weights(tests, cost_map['scenarios'])

    observation_cost = tests.inject(0) do |c, t|
      c + t['quantities'].keys.map { |q| cost_map['observations'][q] }.reduce(0, :+)
    end

    if @options[:concorde]
      require 'concorde'
      require 'tsplib'
      concorde_spec = TSPLIB::TSP.new('tests', 'tests', tests.length)
      0.upto(concorde_spec.dimension - 1) do |i|
        0.upto(i) do |j|
          concorde_spec.weight[i][j] = weights[i][j]
        end
      end
      concorde = Concorde.new(concorde_spec)
      concorde.optimize(@options[:tolerance]) do |msg|
        log(Logger::INFO, "Concorde: #{msg.strip}")
      end
      tour = concorde.tour
      reconfiguration_cost = concorde.cost
    else
      tsp = ::TSP_2opt.new(weights)
      log(Logger::INFO, "initial tour cost: #{tsp.cost}")
      tsp.optimize if @options[:optimize]
      tour = tsp.tour
      reconfiguration_cost = tsp.cost
    end

    log(Logger::INFO, "optimized tour cost: #{reconfiguration_cost}")

    init = tour.find_index { |t| tests[t]['id'] == 0 }
    order = (init == 0) ? tour : tour[init..-1] + tour[0...(init - 1)]
    tests_tour = order.map { |i| tests[i] }

    opt_tests = []
    test_count = 0
    while (pair = tests_tour.take(2)).length == 2 do
      retract = pair[0]['scenarios'] - pair[1]['scenarios']
      apply = pair[1]['scenarios'] - pair[0]['scenarios']
      opt_tests << pair[1].merge(
        'id' => test_count += 1,
        'scenarios' => pair[1]['scenarios'].to_a.sort,
        'retract' => retract.to_a.sort,
        'apply' => apply.to_a.sort
      )
      tests_tour.shift
    end
    log(Logger::INFO, "emitting #{opt_tests.length} test configurations")
    puts JSON.pretty_generate({reconfiguration_cost: reconfiguration_cost, observation_cost: observation_cost, tests: opt_tests})
    0
  end

end

OptimizeTestOrder.new.start
