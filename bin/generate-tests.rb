# frozen_string_literal: true

require 'json'
require 'logger/application'
require 'rgl/adjacency'
require 'rgl/transitivity'
require 'optparse'
require 'securerandom'
require 'digest'

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
      opts.on('-s SUMMARY', '--summary SUMMARY', 'save requirements summary')
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
    tests = []
    path.each do |ss|
      rqmts_direct = rqts_by_ss[ss]
      rqmts = g.adjacent_vertices(ss).inject(rqmts_direct) do |s, v|
        s + rqts_by_ss[v]
      end
      quantities = rqmts.inject(Set.new) do |s, r|
        s << qty_by_rqt[r]
      end.sort
      qh = quantities.inject({}) do |h, q|
        h[q] = { requirements: rqts_by_qty[q].intersection(rqmts).sort }
        h
      end
      quantities_direct = qh.inject([]) do |s, (q, rh)|
        s << q if rh[:requirements].any? { |r| rqmts_direct.include?(r) }
        s
      end
      config = ss.to_a.sort
      tests << {
        uuid: SecureRandom.uuid,
        config_digest: Digest::MD5.hexdigest(config.to_s),
        scenarios: config,
        quantities: qh,
        requirements_direct: rqmts_direct.to_a,
        quantities_direct: quantities_direct
      }
    end
    log(Logger::INFO, "emitting #{tests.length} test configurations")
    puts JSON.pretty_generate(tests)

    if options[:graph]
      log(Logger::INFO, "building configurations graph")
      rg = g.transitive_reduction
      edges = rg.edges.map do |edge|
        {
          from: edge[0].to_a,
          to: edge[1].to_a
        }
      end
      log(Logger::INFO, "emitting configurations graph")
      File.open(options[:graph], 'w') do |f|
        f.puts JSON.pretty_generate(edges)
      end
    end

    rg = g.reverse
    if options[:summary]
      log(Logger::INFO, "building requirements summary")
      summary = []
      requirements.each do |rh|
        configs = rh['configs'].map { |c| Set.new(c['scenarios']) }.inject(Set.new) do |m, ss|
          m << ss.to_a
          m += rg.adjacent_vertices(ss).map { |s| s.to_a }
          m
        end.to_a
        summary << {
          id: rh['id'],
          configs: configs
        }
      end
      log(Logger::INFO, "emitting requirements summary")
      File.open(options[:summary], 'w') do |f|
        f.puts JSON.pretty_generate(summary)
      end
    end

    0
  end

end

GenerateTests.new.start