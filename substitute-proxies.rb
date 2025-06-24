# frozen_string_literal: true

require 'logger/application'
require 'json'
require 'optparse'

class SubstituteProxies < Logger::Application

  def initialize
    super('substitute-proxies')
  end

  def run

    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: substitute-proxies [options]"
      opts.on('-p PROXY_MAP', '--proxy-map PROXY_MAP', String, "Proxy map to substitute")
    end.parse!(into: options)

    raise 'no proxy map' unless (proxy_map_fn = options['proxy-map'.to_sym])

    proxies = JSON.parse(File.open(proxy_map_fn).read).map do |proxy|
      {
        proxies: Set.new(proxy['proxies']),
        for: Set.new(proxy['for'])
      }
    end

    tests = JSON.parse(ARGF.read)

    tests.each do |test|
      new_scenarios = proxies.inject(Set.new(test['scenarios'])) do |ns, proxy|
        if (diff = (ns & proxy[:for])) == proxy[:for]
          log(Logger::INFO, "proxy match for #{test['uuid']}")
          ns - diff + proxy[:proxies]
        else
          ns
        end
      end
      test['scenarios'] = new_scenarios.to_a
    end

    puts JSON.pretty_generate(tests)

    0
  end

end

SubstituteProxies.new.start