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
    requirements.each do |rh|
      rh['configs'].each do |ch|
        scenario_sets << Set.new(ch['scenarios'])
        rqts_by_ss[Set.new(ch['scenarios'])] << rh['id']
      end
      rqts_by_qty[rh['quantity']] << rh['id']
      qty_by_rqt[rh['id']] = rh['quantity']
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
    path.each do |ss|
      requirements = grc.adjacent_vertices(ss).inject(Set.new(rqts_by_ss[ss])) do |s, v|
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
        scenarios: ss.to_a.sort,
        quantities: qh
      }
    end
    log(Logger::INFO, "emitting #{tests.length} test configurations")
    puts JSON.pretty_generate(tests)

    0
  end

end

GenerateTests.new.start