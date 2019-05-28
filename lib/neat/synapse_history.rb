module Neat
  class SynapseHistory
    def initialize(from:, to:, number:, numbers:)
      @from = from
      @to = to
      @number = number
      @numbers = numbers
    end

    attr_reader :number

    def matches?(from:, to:, genome:)
      return false if genome.synapses.length != @numbers.length
      return false if @from.number != from.number || @to.number != to.number

      synapse_numbers = genome.synapses.map(&:number)
      synapse_numbers.all? { |n| @numbers.include?(n) }
    end
  end
end
