module Neat
  class SpeciesPool
    include Enumerable

    STALENESS_THRESHOLD = 15
    CROSSOVER_CHANCE = 0.75 # 75%
    EXCESS_COEFFICENT = 1.0
    WEIGHTED_DIFF_COEFFICENT = 0.5
    COMPABILITY_THRESHOLD = 3.0

    def initialize(generation:)
      @generation = generation
      @species = []
    end

    def each
      @species.each { |species| yield(species) }
    end

    def fitness_average_sum
      @species.map(&:fitness_average).sum
    end

    def separate
      @generation.agents.each do |agent|
        species = @species.find { |s| s.same_species?(agent.genome) }

        if species
          species.agents.push(agent)
        else
          species = Species.new(generation: @generation, champion: agent)
          @species << species
        end
      end
    end

    def sort
      @species.map(&:sort)
      @species.sort_by! { |s| s.agents.map(&:fitness).max }.reverse!
    end

    def cull
      @species.each(&:cull)
    end

    def kill_stale
      @species.reject! { |species| species.staleness >= STALENESS_THRESHOLD }
    end

    def kill_bad
      @species.reject! do |species|
        (species.fitness_average / fitness_average_sum * @generation.agents.count) < 1
      end
    end
  end

  class Species
    def initialize(generation:, champion:)
      @generation = generation
      @staleness = 0
      @agents = [champion].compact
      @champion_genome = champion&.genome&.clone
      @champion = champion&.clone
    end

    attr_reader :staleness, :champion
    attr_accessor :agents

    def fitness_average
      fitness_sum / @agents.count
    end

    def fitness_sum
      @agents.sum(&:fitness)
    end

    def same_species?(genome)
      compatibility = 0.0
      excess_and_disjoint = excess_and_disjoint(genome, @champion_genome)
      average_weight_diff = average_weight_diff(genome, @champion_genome)
      large_synapse_normalizer = [genome.synapses.count - 10.0, 1.0].max

      compatibility = SpeciesPool::EXCESS_COEFFICENT * excess_and_disjoint / large_synapse_normalizer
      compatibility += SpeciesPool::WEIGHTED_DIFF_COEFFICENT * average_weight_diff

      compatibility < SpeciesPool::COMPABILITY_THRESHOLD
    end

    def sort
      @agents.sort_by!(&:fitness).reverse!

      if @agents.first.fitness > @champion.fitness
        @staleness = 0
        @champion = @agents.first.clone
        @champion_genome = @champion.genome.clone
      else
        @staleness += 1
      end
    end

    def cull
      return if @agents.count <= 2
      @agents = @agents.first(@agents.count / 2)
    end

    def make_baby(history)
      return select_parent.clone if rand > SpeciesPool::CROSSOVER_CHANCE

      parent_a, parent_b = select_parent, select_parent
      parent_a, parent_b = parent_b, parent_a if parent_a.fitness > parent_b.fitness

      baby = parent_a.crossover(parent_b)
      baby.genome.mutate(history)
      baby
    end

    def select_parent
      random_fitness = rand(0.0..fitness_sum)

      @agents.shuffle.each do |agent|
        return agent if random_fitness < agent.fitness

        random_fitness -= agent.fitness
      end
    end

    private

    # Returns the number of synapses that dont match
    def excess_and_disjoint(genome_a, genome_b)
      matching = 0.0

      genome_a.synapses.each do |synapse_a|
        genome_b.synapses.each do |synapse_b|
          if synapse_a.number == synapse_b.number
            matching += 1
            break
          end
        end
      end

      genome_a.synapses.count + genome_b.synapses.count - (2 * matching)
    end

    # returns the avereage weight difference between matching genes in the input genomes
    def average_weight_diff(genome_a, genome_b)
      return 0 if genome_a.synapses.empty? || genome_b.synapses.empty?

      matching = 0.0
      total_diff = 0.0

      genome_a.synapses.each do |synapse_a|
        genome_b.synapses.each do |synapse_b|
          if synapse_a.number == synapse_b.number
            matching += 1
            total_diff += (synapse_a.weight - synapse_b.weight).abs
            break
          end
        end
      end

      return 100 if matching.zero?

      total_diff / matching
    end
  end
end
