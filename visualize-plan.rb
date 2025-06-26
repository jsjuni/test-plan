# frozen_string_literal: true

require 'logger/application'
require 'json'
require 'optparse'

TEN_MARKER = '.........|'

class VisualizePlan < Logger::Application
  def initialize
    super('visualize-plan')
  end

  def run

    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: visualize-plan.rb [options]"
      opts.on('-c COSTS', '--costs COSTS', 'scenario costs file')
    end.parse!(into: options)

    raise 'no costs file' unless options[:costs]

    costs = JSON.parse(File.read(options[:costs]))['scenarios']

    js = JSON.parse(ARGF.read)
    tests = js['tests']
    scenarios = Set.new
    tests.each do |t|
      scenarios += t['scenarios']
    end

    puts "length: #{js['length']}"
    rem = tests.length % 10
    tens = (tests.length - rem) / 10
    puts '      ' + TEN_MARKER * tens + '.' * rem + ' changes'

    ss = scenarios.sort_by {|s| costs[s] }
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