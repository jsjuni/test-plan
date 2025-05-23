# frozen_string_literal: true

require 'json'
require 'logger/application'
require 'rgl/adjacency'
require 'rgl/transitivity'
require 'optparse'

class GenerateTests < Logger::Application

  def initialize
    super('generate-tests')

    logger.level = Logger::INFO

  end

  def run

    requirements = JSON.parse(ARGF.read)['requirements']
    log(Logger::INFO, "found #{requirements.length} requirements")

    scenario_sets = Set.new
    rqts_by_ss = Hash.new { |h, k| h[k] = Set.new }
    rqts_by_qty = Hash.new { |h, k| h[k] = Set.new }
    qty_by_rqt = {}
    requirements.each do |h|
      scenario_sets << Set.new(h['scenarios'])
      rqts_by_ss[Set.new(h['scenarios'])] << h['id']
      rqts_by_qty[h['quantity']] << h['id']
      qty_by_rqt[h['id']] = h['quantity']
    end
    log(Logger::INFO, "found #{scenario_sets.size} scenario_sets")

    g = RGL::DirectedAdjacencyGraph.new
    scenario_sets.each do |set|
      g.add_vertex(set)
    end
    g.vertices.each do |v1|
      g.vertices.each do |v2|
        if v1 < v2
          g.add_edge(v2, v1)
        end
      end
    end

    path = g.vertices.to_a
    grc = g.transitive_closure
    proc_count = 0
    tests = []
    while (pair = path.take(2)).length == 2
     requirements = (grc.adjacent_vertices(pair[1]).dup.unshift(pair[1])).inject(Set.new) do |s, v|
        s + rqts_by_ss[v]
      end
      quantities = requirements.inject(Set.new) do |s, r|
        s << qty_by_rqt[r]
      end.sort
      qh = quantities.inject({}) do |h, q|
        h[q] = { requirements: rqts_by_qty[q].intersection(requirements).sort }
        h
      end
      tests << {
        id: proc_count += 1,
        scenarios: pair[1].to_a.sort,
        quantities: qh
      }
      path.shift
    end
    log(Logger::INFO, "emitting #{tests.length} test configurations")
    puts JSON.pretty_generate(tests)

    0
  end

end

GenerateTests.new.start