# frozen_string_literal: true

require 'json'
require 'logger/application'
require 'optparse'

class PruneTests < Logger::Application

  def initialize
    super('prune-tests')

    logger.level=Logger::INFO
  end

  def run

    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: prune-tests.rb [options]"
      opts.on('-s SUFFICIENCY', '--sufficiency SUFFICIENCY', 'sufficiency file')
    end.parse!(into: options)

    raise "no sufficiency file #{options[:sufficiency]}" if options[:sufficiency].nil?

    sufficients_json = JSON.parse(File.read(options[:sufficiency]))

    tests = JSON.parse(ARGF.read)

    sufficients = sufficients_json.inject({}) do |h, sh|
      h.store(sh['id'], Set.new(sh['configs'].map { |c| Set.new(c)})); h
    end

    drop_tests = []

    tests.each do |test|
      t_uuid = test['uuid']
      config = Set.new(test['scenarios'])

      drop_quantities = []
      test['quantities'].each do |q_id, qh|
        drop_requirements = qh['requirements'].reject do |r_id|
          sufficients[r_id].include?(config)
        end
        drop_requirements.each do |drop_r|
          log(Logger::INFO, "drop requirement #{drop_r} from test #{t_uuid}")
          qh['requirements'].delete(drop_r)
        end
        drop_quantities << q_id if qh['requirements'].empty?
      end

      drop_quantities.each do |drop_q|
        log(Logger::INFO, "drop quantity #{drop_q} from test #{t_uuid}")
        test['quantities'].delete(drop_q)
      end
      drop_tests << test if test['quantities'].empty?
    end

    drop_tests.each do |drop_t|
      log(Logger::INFO, "drop test #{drop_t['uuid']}")
      tests.delete(drop_t)
    end

    puts JSON.pretty_generate(tests)

    0
  end
end

PruneTests.new.start
