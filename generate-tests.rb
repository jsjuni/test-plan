# frozen_string_literal: true

require 'json'
require 'logger/application'
require 'rgl/adjacency'
require 'rgl/transitivity'
require 'optparse'
require 'securerandom'

class GenerateTests < Logger::Application

  def initialize
    super('generate-tests')

    logger.level = Logger::INFO

  end

  def run

    options = {}
    OptionParser.new do |opts|
      opts.banner = 'Usage: generate-tests.rb [options]'
      opts.on('-g GRAPH', '--graph GRAPH', 'save configurations graph')
    end.parse!(into: options)

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
    proc_count = 0
    tests = []
    path.each do |ss|
      requirements_direct = rqts_by_ss[ss]
      requirements = g.adjacent_vertices(ss).inject(requirements_direct) do |s, v|
        s + rqts_by_ss[v]
      end
      quantities = requirements.inject(Set.new) do |s, r|
        s << qty_by_rqt[r]
      end.sort
      qh = quantities.inject({}) do |h, q|
        h[q] = { requirements: rqts_by_qty[q].intersection(requirements).sort }
        h
      end
      quantities_direct = qh.inject([]) do |s, (q, rh)|
        s << q if rh[:requirements].any? { |r| requirements_direct.include?(r) }
        s
      end
      tests << {
        id: proc_count += 1,
        uuid: SecureRandom.uuid,
        scenarios: ss.to_a.sort,
        quantities: qh,
        requirements_direct: requirements_direct.to_a,
        quantities_direct: quantities_direct
      }
    end
    log(Logger::INFO, "emitting #{tests.length} test configurations")
    puts JSON.pretty_generate(tests)

    if options[:graph]
      rg = g.transitive_reduction
      edges = rg.edges.map do |edge|
        {
          from: edge[0].to_a,
          to: edge[1].to_a
        }
      end
      File.open(options[:graph], 'w') do |f|
        f.puts JSON.pretty_generate(edges)
      end
    end

    0
  end

end

GenerateTests.new.start