# frozen_string_literal: true

require 'logger/application'
require 'optparse'
require 'json'

class FilterTests < Logger::Application

  def initialize
    super('filter-requirements')

    logger.level = Logger::DEBUG

    @options = {}
    OptionParser.new do |parser|
      parser.on('-w', '--with SCENARIO', 'filter tests requiring SCENARIO')
      parser.on('-x', '--without SCENARIO', 'filter tests not requiring SCENARIO')
    end.parse!(into: @options)
  end

  def run
    tests = JSON.parse(ARGF.read)
    log(Logger::INFO, "found #{tests.length} tests")

    with = @options[:with]
    without = @options[:without]

    new_tests = tests.select do |r|
      (with.nil? || r['scenarios'].include?(with)) && (without.nil? || !r['scenarios'].include?(without))
    end
    log(Logger::INFO, "filter #{new_tests.length} tests")

    puts JSON.pretty_generate(new_tests)

    0
  end

end

FilterTests.new.start
