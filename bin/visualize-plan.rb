# frozen_string_literal: true

require 'logger/application'
require 'json'
require 'optparse'

TEN_MARKER = '.........|'

class VisualizePlan < Logger::Application
  def initialize
    super('visualize-plan')
  end

  def compare(s1, s2, costs)
    if (c1 = (costs[s1] <=> costs[s2])) == 0
      prf1, ord1 = s1.split(/\./)
      prf2, ord2 = s2.split(/\./)
      if (c2 = (prf1 <=> prf2)) == 0
        ord1.to_i <=> ord2.to_i
      else
        c2
      end
    else
      c1
    end
  end

  def run

    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: visualize-plan.rb [options]"
      opts.on('-c COSTS', '--cost-map COSTS', 'scenario costs file')
    end.parse!(into: options)

    raise 'no costs file' unless (cost_map_file = options['cost-map'.to_sym])

    costs = JSON.parse(File.read(cost_map_file))['scenarios']

    js = JSON.parse(ARGF.read)
    tests = js['tests']
    scenarios = Set.new
    tests.each do |t|
      scenarios += t['scenarios']
    end

    puts "cost: #{js['cost']}"
    rem = tests.length % 10
    tens = (tests.length - rem) / 10
    puts '      ' + TEN_MARKER * tens + '.' * rem + ' changes'

    ss = scenarios.sort { |s1, s2| self.compare(s1, s2, costs) }

    ss.each do |scenario|
      label = "%5s " % scenario
      changes = 0
      last_in = false
      data = tests.inject(String.new) do |s, t|
        now_in = t['scenarios'].include?(scenario)
        if now_in != last_in
          last_in = now_in
          changes += 1
        end
        s << (now_in ? '■' : ' ')
      end
      changes += 1 if last_in
      puts label + data + "    %4d" % changes
    end
    0
  end

end

VisualizePlan.new.start