# frozen_string_literal: true

require 'enumerator'

module Configuration

  def retract_for(other)
    self['scenarios'] - other['scenarios']
  end

  def apply_for(other)
    other['scenarios'] - self['scenarios']
  end

  def changes(other)
    retract_for(other) + apply_for(other)
  end

end

class TSP_2opt

  def initialize(path, cost_map)
    @path = path.map do |t|
      mt = t.dup.extend(Configuration)
      mt['scenarios'] = Set.new(t['scenarios'])
      mt
    end
    @cost_map = cost_map
    @path.each { |t| t.extend(Configuration) }
    @length = 0.upto(@path.length - 1).each_cons(2).inject(distance(@path.length - 1, 0)) do |s, p|
      s + distance(p[0], p[1])
    end
  end

  attr_reader :path, :length, :scenarios

  private

  def cost(changes)
    changes.inject(0) do |s, c|
      s + @cost_map[c.to_s]
    end
  end

  def distance(i, j)
    cost(@path[i].changes(@path[j]))
  end

  def swap_edges(i, j)
    i += 1
    while i < j
      @path[i], @path[j] = @path[j], @path[i]
      i += 1
      j -= 1
    end
  end

  public

  def optimize()
    found_improvement = true
    while found_improvement
      found_improvement = false
      for i in 0..(@path.length - 2) do
        for j in (i + 2)..(@path.length - 1 ) do
          length_delta = 0 - distance(i, i + 1) - distance(j, (j + 1) % @path.length) +
                         distance(i, j) + distance(i + 1, (j + 1) % @path.length)
          if length_delta < 0
            swap_edges(i, j)
            @length += length_delta
            found_improvement = true
          end
        end
        0
      end
      0
    end
  end
end


