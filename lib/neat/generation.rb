require_relative 'species'

module Neat
  class Generation
    def initialize(number: 1, count:)
      @number = number
      @count = count
      @agents = []
      @innovation_history = []
      @species = SpeciesPool.new(generation: self)

      @best_agent = nil
      @best_fitness = 0
      @best_score = 0
    end

    attr_reader :number, :count, :best_agent, :best_score
    attr_accessor :agents

    def generate_network
      @agents.each do |agent|
        agent.genome.fully_connect(@innovation_history)
        agent.genome.mutate(@innovation_history)
        agent.genome.generate_network
      end
    end

    def natural_selection(evolve: true)
      @agents.map(&:set_fitness)

      return unless evolve

      @previous_best = @agents.first

      # puts "-> Calculating species..."
      @species.separate
      @species.sort
      @species.cull
      set_best_agent

      # puts "-> Killing stale & bad species..."
      @species.kill_stale
      @species.kill_bad

      fitness_average_sum = @species.fitness_average_sum
      children = []

      puts "-> Generation: #{@number} - Agents: #{@agents.count} - Mutations: #{@innovation_history.count} - Species: #{@species.count}"

      # puts "-> Breeding new generation..."
      @species.each do |specie|
        children << specie.champion.clone
        number_of_children = (specie.fitness_average / fitness_average_sum * @agents.count).floor - 1

        number_of_children.times do
          children << specie.make_baby(@innovation_history)
        end
      end

      children << @previous_best.clone if children.count < @agents.count

      while children.count < @agents.count
        children << @species.first.make_baby(@innovation_history)
      end

      # Increase generation counter
      @number += 1

      @agents = children
      @agents.each { |a| a.genome.generate_network }
    end

    def finished?
      @agents.all?(&:finished?)
    end

    private

    def set_best_agent
      best_agent = @species.first.agents.first
      best_agent.generation = @number

      return if @best_score >= best_agent.score

      puts "-> Old best agent => Score: #{@best_score} - Fitness: #{@best_agent.fitness}" if @best_score > 0
      puts "-> New best agent => Score: #{best_agent.score} - Fitness: #{best_agent.fitness}"

      @best_score = best_agent.score
      @best_agent = best_agent.clone
    end
  end
end
