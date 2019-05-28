require_relative 'node'
require_relative 'synapse'
require_relative 'synapse_history'

module Neat
  class Genome
    LAYERS = 2
    WEIGHT_MUTATION_CHANCE = 0.8 # 80%
    NEW_CONNECTION_CHANCE = 0.05 # 5%
    NEW_NODE_CHANCE = 0.01 # 1%

    def initialize(inputs: 1, outputs: 1, crossover: false)
      @inputs = inputs
      @outputs = outputs
      @layers = LAYERS
      @synapses = []
      @nodes = []
      @network = []
      @next_node = 0
      @bias_node_num = 0
      @next_synapse_number = 1000

      return if crossover

      generate_input_nodes
      generate_output_nodes
      generate_bias_node
    end

    attr_accessor :nodes, :synapses, :layers, :next_node, :bias_node

    def generate_network
      connect_nodes

      @network = []

      @layers.times do |layer|
        @nodes.each do |node|
          @network.push(node) if node.layer == layer
        end
      end
    end

    def connect_nodes
      @nodes.each(&:clear_synapses)
      @synapses.each { |synapse| synapse.from.connect_to(synapse) }
    end

    def feed_forward(inputs)
      raise 'Invalid number of inputs' if inputs.count != @inputs
      raise 'No synapses' if @synapses.empty?
      raise 'No network' if @network.empty?

      # Set output of input nodes
      input_nodes.each.with_index { |node, i| node.output = inputs[i] }

      # Set output of bias node (1)
      bias_node.output = 1

      # Engage nodes
      @network.each(&:engage)

      # Fetch outputs
      outputs = output_nodes.map(&:output)

      # Reset nodes inputs
      @nodes.each(&:clear_input)

      outputs
    end

    def fully_connect(history)
      input_nodes.each do |input|
        output_nodes.each do |output|
          @synapses << Synapse.create(from: input, to: output, genome: self, history: history)
        end
      end

      # Bias connections
      output_nodes.each do |output|
        @synapses << Synapse.create(from: bias_node, to: output, genome: self, history: history)
      end

      connect_nodes
    end

    def fully_connected?
      min_synapses = 0
      nodes_in_layers = Array.new(@layers) { 0 }

      # Count how many nodes per layers
      @nodes.each { |node| nodes_in_layers[node.layer] += 1 }

      # The max synapses for each layer is the nodes * nodes_in_front
      @layers.times do |layer|
        nodes_in_front = nodes_in_layers[layer + 1..-1].sum
        min_synapses += (nodes_in_layers[layer] * nodes_in_front)
      end

      @synapses.count >= min_synapses
    end

    def get_innovation_number(from:, to:, history:)
      previous_synapse = history.find { |synapse| synapse.matches?(from: from, to: to, genome: self) }
      return previous_synapse.number if previous_synapse

      synapse_number = @next_synapse_number
      synapse_numbers = @synapses.map(&:number)

      history.push(SynapseHistory.new(from: from, to: to, number: synapse_number, numbers: synapse_numbers))
      @next_synapse_number += 1

      synapse_number
    end

    def mutate(history)
      add_connection(history) if @synapses.empty?
      @synapses.each(&:mutate) if rand < WEIGHT_MUTATION_CHANCE
      add_connection(history) if rand < NEW_CONNECTION_CHANCE
      add_node(history) if rand < NEW_NODE_CHANCE
    end

    def add_connection(history)
      return if fully_connected?

      node_a, node_b = @nodes.sample(2)
      node_a, node_b = @nodes.sample(2) until can_connect?(from: node_a, to: node_b)

      node_a, node_b = node_b, node_a if node_a.layer > node_b.layer

      @synapses << Synapse.create(from: node_a, to: node_b, genome: self, history: history)

      connect_nodes
    end

    def add_node(history)
      return add_connection(history) if @synapses.empty?

      random_synapse = @synapses.reject { |s| s.from == bias_node }.sample
      return if random_synapse.nil?

      random_synapse.enabled = false
      new_node = HiddenNode.new(number: @next_node, layer: 0)
      @next_node += 1

      @nodes << new_node
      @synapses << Synapse.create(from: random_synapse.from, to: new_node, weight: 1, genome: self, history: history)
      @synapses << Synapse.create(from: new_node, to: random_synapse.to, weight: random_synapse.weight, genome: self, history: history)
      @synapses << Synapse.create(from: bias_node, to: new_node, weight: 0, genome: self, history: history)

      if new_node.layer == random_synapse.to.layer
        @nodes.select { |n| n.layer > new_node.layer }.each do |node|
          node.layer += 1
        end

        @layers += 1
      end

      connect_nodes
    end

    def clone
      clone = self.class.new(inputs: @inputs, outputs: @outputs, crossover: true)
      clone.nodes = @nodes
      clone.synapses = @synapses.map { |s| s.clone(from: clone.get_node(s.from.number), to: clone.get_node(s.to.number)) }
      clone.layers = @layers
      clone.next_node = @next_node
      clone.bias_node = @bias_node
      clone.connect_nodes
      clone
    end

    def crossover(parent)
      child = self.class.new(inputs: @inputs, outputs: @outputs, crossover: true)
      child.synapses = []
      child.nodes = []
      child.layers = @layers
      child.next_node = @next_node
      child.bias_node = @bias_node

      child_synapses = []
      is_enabled = []

      # Inherit all synapses
      @synapses.each do |synapse|
        set_enabled = true
        parent_synapse = parent.genome.synapses.find { |s| s.number == synapse.number }

        # Found parent matching synapse
        if parent_synapse

          # Either of them is disabled?
          if synapse.disabled? || parent_synapse.disabled?
            # 75% chance of disabling child synapse
            set_enabled = false if rand < 0.75
          end

          # Use either synapse
          child_synapses << [synapse, parent_synapse].sample
        else # Disjoint or excess synapse
          child_synapses << synapse
          is_enabled << synapse.enabled
        end

        is_enabled << set_enabled
      end

      @nodes.each { |node| child.nodes << node.clone }

      child_synapses.each.with_index do |synapse, index|
        node_a = child.get_node(synapse.from.number)
        node_b = child.get_node(synapse.to.number)
        child.synapses << synapse.clone(from: node_a, to: node_b, enabled: is_enabled[index])
      end

      child.connect_nodes
      child
    end

    def get_node(number)
      @nodes.find { |node| node.number == number }
    end

    private

    def can_connect?(from:, to:)
      from.layer != to.layer && !from.connected_to?(to)
    end

    def input_nodes
      @nodes.select { |node| node.is_a?(InputNode) }
    end

    def output_nodes
      @nodes.select { |node| node.is_a?(OutputNode) }
    end

    def bias_node
      @bias_node ||= @nodes.find { |node| node.number == @bias_node_num }
    end

    def generate_input_nodes
      @inputs.times do |i|
        @nodes.push(InputNode.new(number: i, layer: 0))
        @next_node += 1
      end
    end

    def generate_output_nodes
      @outputs.times do |i|
        @nodes.push(OutputNode.new(number: @inputs + i, layer: 1))
        @next_node += 1
      end
    end

    def generate_bias_node
      @bias_node_num = @next_node
      @nodes.push(BiasNode.new(number: @bias_node_num, layer: 0))
      @next_node += 1
    end
  end
end
