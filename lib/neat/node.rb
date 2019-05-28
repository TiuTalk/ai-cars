require './lib/utils'

module Neat
  class Node
    include Utils

    def initialize(number:, layer:)
      @number = number
      @layer = layer
      @input = 0
      @output = 0
      @synapses = []
    end

    attr_reader :type, :number
    attr_accessor :input, :output, :layer

    def to_s
      "#{self.class.name} ##{number} (layer #{layer})"
    end

    def connect_to(synapse)
      @synapses.push(synapse)
    end

    def clear_synapses
      @synapses = []
    end

    def clear_input
      @input = 0
    end

    def connected_to?(node)
      return false if node.layer == layer

      if node.layer < layer
        @synapses.any? { |synapse| synapse.to == self }
      else
        @synapses.any? { |synapse| synapse.to == node }
      end
    end

    def engage
      @output = sigmoid(@input) unless @layer.zero?

      @synapses.select(&:enabled?).each do |synapse|
        synapse.to.input += (synapse.weight * @output)
      end
    end

    def clone
      self.class.new(number: number, layer: layer)
    end
  end

  class InputNode < Node; end
  class OutputNode < Node; end
  class HiddenNode < Node; end
  class BiasNode < Node; end
end
