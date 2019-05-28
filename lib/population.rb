require 'forwardable'
require './lib/neat/generation'
require_relative 'car'

class Population
  extend Forwardable

  delegate :number => :@generation

  attr_reader :cars, :count, :speed

  def initialize(track:, count:)
    @track = track
    @count = count
    @cars = []
    @speed = 1
    @generation = Neat::Generation.new(count: @count)
  end

  def populate!
    puts "Creating population of #{@count} cars..."
    @cars = Array.new(@count) { Car.new(track: @track) }
    @generation.agents = @cars.map(&:agent)
    @generation.generate_network
  end

  def speedup!
    @speed = [@speed * 2, 16].min
  end

  def slowdown!
    @speed = [1, @speed / 2].max
  end

  def update(evolve: true)
    @speed.times do
      @cars.reject(&:finished?).each do |car|
        car.look
        car.think
        car.update
      end
    end

    # Build new array of @cars and @agents
    if @generation.finished?
      @cars.sort_by(&:fitness).last(3).each { |car| puts car }
      @generation.natural_selection(evolve: evolve)
      @cars = @generation.agents.map(&:object)
    end
  end

  def force_natural_selection
    @cars.each(&:finished!)
  end

  def draw
    @cars.each(&:draw)
  end
end
