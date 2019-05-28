require_relative 'genome'

module Neat
  class Agent
    AGENT_UPDATE_INTERVAL = 100 # ms

    extend Forwardable

    delegate %i[set_fitness] => :@object

    attr_reader :outputs, :lifespan, :object
    attr_accessor :inputs, :genome, :generation, :fitness, :score, :best_score

    def initialize(object:, inputs: 1, outputs: 1)
      @object = object
      @generation = 0
      @inputs = []
      @outputs = []
      @lifespan = 0
      @fitness = 0
      @score = 0
      @best_score = 0
      @finished = false
      @genome = Genome.new(inputs: inputs, outputs: outputs)
    end

    def to_s
      "#{@object.class.name} #{object_id} - Score: #{score} - Fitness - #{fitness}"
    end

    def look(inputs)
      @inputs = inputs
    end

    def think
      @outputs = genome.feed_forward(inputs)
    end

    def update
      @lifespan += 1
    end

    def finished!
      @finished = true
    end

    def finished?
      @finished == true
    end

    def alive?
      !finished?
    end

    def crossover(parent)
      object = @object.clone(agent: self)
      object.agent = self.class.new(object: object, inputs: @inputs.count, outputs: @outputs.count)
      object.agent.genome = genome.crossover(parent)
      object.agent.genome.generate_network
      object.agent
    end

    def clone
      object = @object.clone(agent: self)
      object.agent = self.class.new(object: object, inputs: @inputs.count, outputs: @outputs.count)
      object.agent.genome = genome.clone
      object.agent.fitness = @fitness
      object.agent.genome.generate_network
      object.agent.generation = @generation
      object.agent.best_score = @best_score
      object.agent
    end
  end
end
