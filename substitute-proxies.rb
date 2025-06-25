# frozen_string_literal: true

require 'logger/application'
require 'json'
require 'optparse'

class SubstituteProxies < Logger::Application

  def initialize
    super('substitute-proxies')
  end

  def substitute(proxies, config, id)
    proxies.inject(Set.new(config)) do |ns, proxy|
      if (diff = (ns & proxy[:for])) == proxy[:for]
        log(Logger::INFO, "proxy match for #{id}")
        ns - diff + proxy[:proxies]
      else
        ns
      end
    end
  end

  def run

    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: substitute-proxies [options]"
      opts.on('-p PROXY_MAP', '--proxy-map PROXY_MAP', String, "Proxy map to substitute")
      opts.on('-v', '--requirements-summary', 'proxy requirements summary')
      opts.on('-t', '--tests', 'proxy tests')
    end.parse!(into: options)

    raise 'no proxy map' unless (proxy_map_fn = options['proxy-map'.to_sym])
    proxy_r = options['requirements-summary'.to_sym]
    proxy_t = options[:tests]
    raise 'exactly one of -v or -t required' if (proxy_r && proxy_t) || (!proxy_r && !proxy_t)

    proxies = JSON.parse(File.open(proxy_map_fn).read).map do |proxy|
      {
        proxies: Set.new(proxy['proxies']),
        for: Set.new(proxy['for'])
      }
    end

    if proxy_t
      tests = JSON.parse(ARGF.read)

      tests.each do |test|
        new_scenarios = substitute(proxies, test['scenarios'], "test #{test['uuid']}")
        test['scenarios'] = new_scenarios.to_a
      end

      puts JSON.pretty_generate(tests)
    end

    0
  end

end

SubstituteProxies.new.start