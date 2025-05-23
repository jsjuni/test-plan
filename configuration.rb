# frozen_string_literal: true

class Configuration

  @cost_map = Hash.new(1)

  def initialize(id, scenarios)
    @id = id
    @scenarios = scenarios
  end
  attr_reader :scenarios

  def self.cost_map=(map)
    @cost_map = map
  end

  def each
    @scenarios.each do |s|
      yield s
    end
  end

  def retract_for(other)
    @scenarios - other.scenarios
  end

  def apply_for(other)
    other.scenarios - @scenarios
  end

  def distance(other)
    (retract_for(other) + apply_for(other)).map { |s| @cost_map[s] }.inject(0) { |s, c| s + c }
  end

  def <(other)
    @scenarios < other.scenarios
  end

end
