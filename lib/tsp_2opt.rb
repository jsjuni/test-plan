# frozen_string_literal: true

require 'enumerator'
require 'delegate'

class TSP_2opt

  def initialize(weights)
    @dimension = weights.length
    @weights = weights
    @tour = (0..(@dimension - 1)).to_a
    @cost = 0.upto(@dimension - 1).each_cons(2).inject(distance(@dimension - 1, 0)) do |s, p|
      s + distance(p[0], p[1])
    end
  end

  attr_reader :dimension, :tour, :cost

  def distance(i, j)
    if j < i
      @weights[i][j]
    else
      @weights[j][i]
    end
  end

  def swap_edges(i, j)
    i += 1
    while i < j
      @tour[i], @tour[j] = @tour[j], @tour[i]
      i += 1
      j -= 1
    end
  end
  public

  def optimize()
    found_improvement = true
    while found_improvement
      found_improvement = false
      for i in 0..(@dimension - 2) do
        for j in (i + 2)..(@dimension - 1) do
          cost_delta = 0 - distance(@tour[i], @tour[i + 1]) - distance(@tour[j], @tour[(j + 1) % @dimension]) +
                       distance(@tour[i], @tour[j]) + distance(@tour[i + 1], @tour[(j + 1) % @dimension])
          if cost_delta < 0
            swap_edges(i, j)
            @cost += cost_delta
            found_improvement = true
          end
        end
      end
    end
    self
  end
end
