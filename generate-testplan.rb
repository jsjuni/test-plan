# frozen_string_literal: true

require 'logger/application'
require 'date'
require 'json'

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
    js = JSON.parse(ARGF.read)

    tests = js['tests']
    tests.last['final'] = true
    nc = tests.length
    ns = tests.inject(Set.new) { |s, t| s + t['scenarios'] }.length
    nq = tests.inject(Set.new) { |s, t| s + t['quantities'].keys }.length
    all_rqts = tests.inject(Set.new) { |s, t| s + t['quantities'].values.map { |v| v['requirements'] }.flatten }
    nr = all_rqts.length
    nsc = js['length']

    qty_by_rqt = { }
    test_abbrevs_by_rqt = Hash.new { |h, k| h[k] = Set.new }
    tests.each do |test|
      test_abbrev = "Test #{test['id']} {#{test['scenarios'].sort_by(&:serial).join(', ')}}"
      test['quantities'].each do |quantity, rh|
        rh['requirements'].each do |rqt|
          qty_by_rqt[rqt] = quantity
          test_abbrevs_by_rqt[rqt] << test_abbrev
        end
      end
    end

    puts '= Test Plan'
    puts 'Test Plan Author'
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
    puts "* Reconfiguration Costs: #{nsc} (#{"%.1f" % (nsc.to_f / nc)} per configuration)"
    puts
    puts 'A configuration is a unique combination of scenarios. There is one test for each configuration.'
    puts 'During each test, all quantities constrained by any requirement that applies during any scenario'
    puts 'in that configuration are observed and recorded.'
    puts
    puts 'Tests are ordered such that the scenario changes between tests are reduced.'
    puts 'Specific instructions for which scenarios to retract and apply are provided for each test.'
    puts
    puts '== Tests'
    puts

    tests.each do |test|
      puts "=== Test #{test['id']}"
      puts
      puts '==== Configuration'
      puts
      puts 'Applicable scenarios:'
      puts
      test['scenarios'].sort_by(&:serial).each do |scenario|
        puts "* #{scenario}"
      end
      puts
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
        puts '==== Configuration Changes After Test'
        puts
        puts 'Retract these scenarios:'
        puts
        test['scenarios'].sort_by(&:serial).each do |scenario|
          puts "* #{scenario}"
        end
        puts
      end
      puts '==== Requirements in Scope'
      puts
      test['quantities'].values.map { |v| v['requirements'] }.flatten.uniq.sort_by(&:serial).each do |req|
        puts "* #{req}"
      end
      puts
      puts '==== Observations'
      puts
      puts 'Record observations of these quantities:'
      puts
      test['quantities'].keys.sort_by(&:serial).each do |quantity|
        puts "* #{quantity}"
      end
      puts
    end

    puts '== Summary'
    puts
    puts '|==='
    puts '| Requirement | Quantity | Test(s) '
    all_rqts.sort_by(&:serial).each do |req|
      rs = test_abbrevs_by_rqt[req].length
      puts ".#{rs}+| #{req}"
      puts ".#{rs}+| #{qty_by_rqt[req]}"
      test_abbrevs_by_rqt[req].sort_by { |ta| ta.match(/Test (\d+)/)[1].to_i }.each do |ta|
        puts "|#{ta}"
        puts
      end
    end
    puts '|==='
    puts
    0
  end
end

GenerateTestplan.new.start