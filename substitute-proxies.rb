# frozen_string_literal: true

require 'logger/application'
require 'json'
require 'optparse'
require 'securerandom'

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
    end.to_a
  end

  def merge_tests(tl)

    quantities = tl.inject({}) do |qh, test|
      test['quantities'].each do |tq, tqh|
        if qh.has_key?(tq)
          qh[tq]['requirements'] = (qh[tq]['requirements'] + tqh['requirements']).uniq.sort
        else
          qh[tq] = tqh
        end
      end
      qh
    end

    uuid = SecureRandom.uuid
    log(Logger::INFO, "merged test #{uuid}")
    {
      uuid: uuid,
      scenarios: tl.first['scenarios'],
      quantities: quantities,
      requirements_direct: tl.flat_map { |test| test['requirements_direct'] }.uniq.sort,
      quantities_direct: tl.flat_map { |test| test['quantities_direct'] }.uniq.sort
    }

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

    data = JSON.parse(ARGF.read)

    if proxy_r

      requirements = data

      requirements.each do |requirement|
        new_configs = requirement['configs'].map do |config|
          substitute(proxies, config, requirement['id'])
        end
        requirement['configs'] = new_configs
      end

      puts JSON.pretty_generate(requirements)

    elsif proxy_t

      tests = data

      tests.each do |test|
        new_scenarios = substitute(proxies, test['scenarios'], "test #{test['uuid']}")
        test['scenarios'] = new_scenarios.to_a
      end

      sc_map = tests.inject(Hash.new { |h,k| h[k] = Set.new }) do |map, test|
        map[test['scenarios'].hash] << test
        map
      end

      new_tests = sc_map.inject([]) do |r, (sh, tl)|
        if tl.length == 1
          r << tl.first
        else
          r << merge_tests(tl)
        end
        r
      end

      puts JSON.pretty_generate(new_tests)

    end

    0
  end

end

SubstituteProxies.new.start