# frozen_string_literal: true

require 'logger/application'
require 'date'
require 'json'
require 'optparse'

class String
  def serial
    gsub(/\D+/, '').to_i
  end
end

class GenerateTestplan < Logger::Application

  def initialize
    super('generate-testplan')
  end

  def run
    @options = {}
    OptionParser.new do |opts|
      opts.on('--optimized')
      opts.on('-c HEAT_MAP', '--configuration HEAT_MAP', 'optional configuration costs heat map')
      opts.on('-o HEAT_MAP', '--observation HEAT_MAP', 'optional observation costs heat map')
    end.parse!(into: @options)

    c_map = @options[:configuration]
    o_map = @options[:observation]

    js = JSON.parse(ARGF.read)

    tests = js['tests']
    tests.last['final'] = true
    nc = tests.length
    ns = tests.inject(Set.new) { |s, t| s + t['scenarios'] }.length
    nq = tests.inject(Set.new) { |s, t| s + t['quantities'].keys }.length
    no = tests.inject(0) { |s, t| s + t['quantities'].length }
    nr = tests.inject(Set.new) { |s, t| s + t['quantities'].values.map { |v| v['requirements'] }.flatten }.length
    rc = js['reconfiguration_cost']
    oc = js['observation_cost']

    qty_by_rqt = { }
    test_abbrevs_by_qty = Hash.new { |h, k| h[k] = Set.new }
    test_abbrevs_by_rqt = Hash.new { |h, k| h[k] = Set.new }
    tests.each do |test|
      test_abbrev = "Test #{test['id']} {#{test['scenarios'].sort_by(&:serial).join(', ')}}"
      test['quantities'].each do |quantity, rh|
        test_abbrevs_by_qty[quantity] << test_abbrev
        rh['requirements'].each do |rqt|
          qty_by_rqt[rqt] = quantity
          test_abbrevs_by_rqt[rqt] << test_abbrev
        end
      end
    end

    puts '= Test Plan'
    puts 'Test Plan Author'
    puts ":toc:"
    puts ":toclevels: 2"
    puts "#{Date.today.to_s}"
    puts
    puts '== Overview'
    puts
    puts "Census:"
    puts
    puts "* Requirements: #{nr}"
    puts "* Scenarios: #{ns}"
    puts "* Quantities: #{nq}"
    puts "* Configurations: #{nc}"
    puts "* Configuration Costs: #{rc}"
    puts "* Observations: #{no}"
    puts "* Observation Costs: #{oc}"
    puts "* Total Costs: #{rc + oc}"
    puts
    puts 'A configuration is a unique combination of scenarios. There is one test for each configuration.'
    puts 'During each test, all quantities constrained by any requirement that applies during any scenario'
    puts 'in that configuration are observed and recorded.'
    puts
    if @options[:optimized]
      puts 'Tests are ordered such that the scenario changes between tests are reduced.'
    end
    puts 'Specific instructions for which scenarios to retract and apply are provided for each test.'
    puts
    if c_map || o_map
      puts '== Cost Heat Maps'
      if c_map
        puts '=== Configuration Costs'
        puts "image::#{File.basename(c_map)}[Configuration Costs HeatMap]"
        puts
      end
      if o_map
        puts '=== Observation Costs'
        puts "image::#{File.basename(o_map)}[Observation Costs HeatMap]"
        puts
      end
      puts
    end
    puts '== Tests'
    puts
    puts "For each test,"
    puts "an asterisk following a requirement indicates that the requirement explicitly applies during"
    puts "the configuration (scenario set) of that test. A requirement without an asterisk applies during some less"
    puts "restrictive configuration and therefore in this configuration by implication."
    puts
    puts "A asterisk following a quantity indicates that the quantity is constrained by an"
    puts "explicitly-applicable requirement."
    puts

    tests.each do |test|
      puts '[discrete]'
      puts "=== Test #{test['id']}"
      puts "* Test UUID: #{test['uuid']}"
      puts "* Configuration Digest: #{test['config_digest']}"
      puts
      puts '[discrete]'
      puts '==== Configuration'
      puts
      puts 'Applicable scenarios:'
      puts
      test['scenarios'].sort_by(&:serial).each do |scenario|
        puts "* #{scenario}"
      end
      puts
      puts '[discrete]'
      puts '==== Configuration Changes Before Test'
      puts
      unless (retract = test['retract']).empty?
        puts 'Retract these scenarios:'
        puts
        retract.sort_by(&:serial).each do |scenario|
          puts "* #{scenario}"
        end
        puts
      end
      unless (apply = test['apply']).empty?
        puts 'Apply these scenarios:'
        puts
        apply.sort_by(&:serial).each do |scenario|
          puts "* #{scenario}"
        end
        puts
      end
      if test['final']
        puts '[discrete]'
        puts '==== Configuration Changes After Test'
        puts
        puts 'Retract these scenarios:'
        puts
        test['scenarios'].sort_by(&:serial).each do |scenario|
          puts "* #{scenario}"
        end
        puts
      end
      puts '[discrete]'
      puts '==== Requirements in Scope'
      puts
      test['quantities'].values.map { |v| v['requirements'] }.flatten.uniq.sort_by(&:serial).each do |req|
        direct = (test['requirements_direct'].include?(req)) ? '*' : ''
        puts "* #{req}#{direct}"
      end
      puts
      puts '[discrete]'
      puts '==== Observations'
      puts
      puts 'Record observations of these quantities:'
      puts
      test['quantities'].keys.sort_by(&:serial).each do |quantity|
        direct = (test['quantities_direct'].include?(quantity)) ? '*' : ''
        puts "* #{quantity}#{direct}"
      end
      puts
    end

    puts '== Summary Tables'
    puts
    puts '=== Summary by Requirement'
    puts
    puts '|==='
    puts '| Requirement | Quantity | Test(s) '
    test_abbrevs_by_rqt.keys.sort_by(&:serial).each do |req|
      rs = test_abbrevs_by_rqt[req].length
      puts ".#{rs}+| #{req}"
      puts ".#{rs}+| #{qty_by_rqt[req]}"
      test_abbrevs_by_rqt[req].sort_by { |ta| ta.match(/Test (\d+)/)[1].to_i }.each do |ta|
        xref = '_test_' + ta.match(/Test (\d+)/)[1]
        puts "|<<#{xref},#{ta}>>"
        puts
      end
    end
    puts '|==='
    puts

    puts '=== Summary by Quantity'
    puts
    puts '|==='
    puts '| Quantity | Test(s) '
    test_abbrevs_by_qty.keys.sort_by(&:serial).each do |qty|
      qs = test_abbrevs_by_qty[qty].length
      puts ".#{qs}+| #{qty}"
      test_abbrevs_by_qty[qty].sort_by { |ta| ta.match(/Test (\d+)/)[1].to_i }.each do |ta|
        xref = '_test_' + ta.match(/Test (\d+)/)[1]
        puts "|<<#{xref},#{ta}>>"
        puts
      end
    end
    puts '|==='
    puts

    0
  end
end

GenerateTestplan.new.start