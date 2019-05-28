module Neat
  class Synapse
    include Utils

    MUTATION_RATE = 0.1 # 10%

    def initialize(from:, to:, number:, weight: nil)
      @from = from
      @to = to
      @weight = weight || rand(-1.0..1.0)
      @number = number
      @enabled = true
    end

    attr_reader :from, :to, :number, :weight
    attr_accessor :enabled

    def self.create(from:, to:, genome:, history:, weight: nil)
      number = genome.get_innovation_number(from: from, to: to, history: history)
      new(from: from, to: to, number: number, weight: nil)
    end

    def clone(from:, to:, enabled: nil)
      synapse = self.class.new(from: from, to: to, number: @number, weight: @weight)
      synapse.enabled = enabled || @enabled
      synapse
    end

    def enabled?
      @enabled == true
    end

    def disabled?
      !enabled?
    end

    def mutate
      if rand < MUTATION_RATE
        @weight = rand(-1.0..1.0)
      else
        @weight += random_gaussian / 50.0
        @weight = [[-1, @weight].max, 1].min
      end
    end

    def to_s
      "#{self.class.name} ##{number} (#{from} -> #{to}, weight #{weight})"
    end
  end
end
