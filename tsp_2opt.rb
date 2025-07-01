# frozen_string_literal: true

require 'enumerator'
require 'delegate'

module TSP

  class Path < DelegateClass(Array)

    alias :_length :length

    def initialize(array)
      super(array)
      @length = 0.upto(_length - 1).each_cons(2).inject(distance(_length - 1, 0)) do |s, p|
        s + distance(p[0], p[1])
      end
    end

    attr_accessor :length

    def swap_edges(i, j)
      i += 1
      while i < j
        self[i], self[j] = self[j], self[i]
        i += 1
        j -= 1
      end
    end

    def distance(i, j)
      raise NotImplementedError
    end

  end


  class TSP_2opt

    def initialize(path)
      @path = path
    end

    def length
      @path.length
    end

    attr_reader :path

    public

    def optimize()
      found_improvement = true
      while found_improvement
        found_improvement = false
        for i in 0..(@path._length - 2) do
          for j in (i + 2)..(@path._length - 1 ) do
            length_delta = 0 - @path.distance(i, i + 1) - @path.distance(j, (j + 1) % @path._length) +
                           @path.distance(i, j) + @path.distance(i + 1, (j + 1) % @path._length)
            if length_delta < 0
              @path.swap_edges(i, j)
              @path.length += length_delta
              found_improvement = true
            end
          end
        end
      end
      self
    end
  end

end
