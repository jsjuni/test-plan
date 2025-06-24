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

    sufficients = JSON.parse(File.read(options[:sufficiency]))

    tests = JSON.parse(ARGF.read)

    sufficients.each do |suff|
      s_r_id = suff['id']
      s_configs = suff['configs']

      drop_tests = []

      tests.each do |test|
        t_uuid = test['uuid']
        config = Set.new(test['scenarios'])
        test_logged = false

        drop_quantities = []
        test['quantities'].each do |q_id, qh|
          unless s_configs.any? { |s_config| Set.new(s_config) == config }
            if qh['requirements'].include?(s_r_id)
              unless test_logged
                log(Logger::INFO, "prune test #{t_uuid}")
                test_logged = true
              end
              log(Logger::INFO, "  drop requirement #{s_r_id}")
              qh['requirements'].delete(s_r_id)
            end
            drop_quantities << q_id if qh['requirements'].empty?
          end
        end

        drop_quantities.each do |drop_q|
          log(Logger::INFO, "  drop quantity #{drop_q}")
          test['quantities'].delete(drop_q)
        end
        drop_tests << test if test['quantities'].empty?
      end

      drop_tests.each do |drop_t|
        log(Logger::INFO, "drop test #{drop_t['uuid']}")
        tests.delete(drop_t)
      end
    end

    puts JSON.pretty_generate(tests)

    0
  end
end

PruneTests.new.start
