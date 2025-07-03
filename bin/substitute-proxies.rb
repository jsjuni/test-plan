# frozen_string_literal: true

require 'logger/application'
require 'json'
require 'optparse'
require 'securerandom'

class SubstituteProxies < Logger::Application

  def initialize
    super('substitute-proxies')
  end

  def substitute(proxies, situation, id)
    ss = proxies.inject(Set.new(situation['scenarios'])) do |ns, proxy|
      if (diff = (ns & proxy[:for])) == proxy[:for]
        log(Logger::INFO, "proxy match for #{id}")
        ns - diff + proxy[:proxies]
      else
        ns
      end
    end.to_a
    { scenarios: ss }
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

    data = JSON.parse(ARGF.read)

    data['requirements'].each do |requirement|
      configs = requirement['situations'].map do |situation|
        substitute(proxies, situation, requirement['id'])
      end
      requirement['configs'] = configs
    end

    puts JSON.pretty_generate(data)

    0
  end

end

SubstituteProxies.new.start