# frozen_string_literal: true

require 'logger/application'
require 'json'
require 'base64'

class GraphToDot < Logger::Application

  def initialize(appname = nil)
    super('graph-to-dot')
  end

  def run

    graph = JSON.parse(ARGF.read)

    vertices = graph.inject(Hash.new { |h, k| h[k] = Set.new }) do |vertices, node|
      f = node['from']
      vertices[f.size] << f
      t = node['to']
      vertices[t.size] << t
      vertices
    end

    node_label = {}
    node_id = {}
    vertices.each do |size, set|
      set.each do |configuration|
        unless node_label[configuration]
          node_label[configuration] = "{#{configuration.join(', ')}}"
          node_id[configuration] = Base64.urlsafe_encode64(node_label[configuration], :padding => false)
          end
      end
    end

    puts 'digraph G {'
    puts '  graph [rankdir = LR]'
    puts '  node [shape = none]'
    vertices.each do |size, nodes|
      puts '  {'
      puts '    rank = same'
      nodes.each do |node|
        puts %Q{    #{node_id[node]} [label = "#{node_label[node]}"]}
      end
      puts '  }'
    end
    graph.each do |h|
      puts %Q{  #{node_id[h['from']]} -> #{node_id[h['to']]}}
    end
    puts '}'

    0
  end

end

GraphToDot.new.start
