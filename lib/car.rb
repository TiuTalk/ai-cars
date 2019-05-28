require 'forwardable'
require './lib/neat/agent'

class Car
  GOAL_TIMEOUT = 3_000
  ROAD_MAX_DISTANCE = 20
  LAPS_LIMIT = 3

  SIGHT_ANGLE = 180
  SIGHT_STEPS = 45
  SIGHT_LENGTH = 100

  extend Forwardable

  delegate %i[finished? alive? finished! fitness score lifespan] => :@agent

  attr_accessor :agent

  def initialize(track:, position: nil, angle: nil, agent: nil)
    # Phisycs
    @track = track
    @position = position.clone || track.start.clone
    @vel_x = @vel_y = 0
    @angle = angle || track.start_angle

    # Visual
    @sprite = Gosu::Image.new('assets/car.png')
    @scale = 0.035
    @label = Gosu::Font.new(11)
    @goal = next_goal
    @laps = 0

    # Timers
    @last_agent_update = Gosu.milliseconds
    @last_goal_reached = Gosu.milliseconds

    # Neat agent
    @agent = agent || Neat::Agent.new(object: self, inputs: vision.count, outputs: 2)
  end

  def to_s
    "Car #{object_id} - Score: #{score} - Fitness: #{fitness} - Vision: #{vision}"
  end

  def draw
    return if finished?

    @sprite.draw_rot(@position.x, @position.y, 1, @angle, 0.5, 0.5, @scale, @scale, color)
    # @sight.each { |sight| sight.draw(Gosu::Color.new(125, 0, 255, 255)) } if @sight
    # @label.draw_text_rel("Road: #{distance_to_road.round(2)} (#{angle_to_road.round(2)}o)", @position.x, @position.y + 30, 2, 0.5, 1)
    # @label.draw_text_rel("Goal: #{distance_to_goal.round(2)} (#{angle_to_goal.round(2)}o)", @position.x, @position.y + 40, 2, 0.5, 1)
    # @label.draw_text_rel("Distance: #{distance_to_road.round(2)}", @position.x, @position.y + 30, 2, 0.5, 1)
    # @label.draw_text_rel("Score: #{score}", @position.x, @position.y + 40, 2, 0.5, 1)
    # Line.new(p1: @position, p2: @goal.position).draw(Gosu::Color.new(70, 255, 255, 0))
  end

  def vision
    @sight = calculate_sight
    @sight.map { |line| @goal.position.distance_to_line(line) }
  end

  # Gather input from the world
  def look
    @agent.inputs = vision
  end

  # Make movement decision based on the outputs
  def think
    @agent.think

    turn_left if @agent.outputs[0] < 0.3
    turn_right if @agent.outputs[0] > 0.6
    accelerate if @agent.outputs[1] < 0.3
    send(:break) if @agent.outputs[1] > 0.6
  end

  # Process the movement
  def update
    move
    check_position
    check_goal

    @agent.update if update_agent?
  end

  def turn_left
    @angle -= 4.5
    @angle %= -360.0 if @angle.negative?
  end

  def turn_right
    @angle += 4.5
    @angle %= 360.0 if @angle.positive?
  end

  def accelerate
    @vel_x += Gosu.offset_x(@angle, 0.1)
    @vel_y += Gosu.offset_y(@angle, 0.1)
  end

  def break
    @vel_x *= 0.95
    @vel_y *= 0.95
  end

  def set_fitness
    @agent.fitness = 1 + ((score**2) / lifespan)
  end

  def clone(agent:)
    self.class.new(track: @track, agent: agent)
  end

  private

  def calculate_sight
    @sight = (0..SIGHT_ANGLE).step(SIGHT_STEPS).map do |angle|
      Line.new(p1: @position, p2: @position.jump(SIGHT_LENGTH, angle + @angle - 90))
    end
  end

  def update_agent?
    return false if Gosu.milliseconds - @last_agent_update < Neat::Agent::AGENT_UPDATE_INTERVAL

    @last_agent_update = Gosu.milliseconds
  end

  def move
    @position.x += @vel_x
    @position.y += @vel_y

    @vel_x *= 0.95
    @vel_y *= 0.95
  end

  def check_position
    @agent.finished! unless on_the_road?
    @agent.finished! if @laps >= LAPS_LIMIT
  end

  def check_goal
    while distance_to_goal <= 30
      percentage = ((GOAL_TIMEOUT - 0.0 - time_since_last_goal_reached) / GOAL_TIMEOUT)

      @agent.score += (100.0 * percentage).round(2)
      @agent.score = @agent.score.round(2)
      @goal = next_goal

      @last_goal_reached = Gosu.milliseconds
    end

    @agent.finished! if time_since_last_goal_reached > GOAL_TIMEOUT
  end

  def time_since_last_goal_reached
    Gosu.milliseconds - @last_goal_reached
  end

  def next_goal
    if @goal.nil?
      @track.goals.first
    elsif @goal == @track.goals.last
      @laps += 1
      @agent.score += 100.0
      @track.goals.first
    else
      @track.goals[@track.goals.index(@goal) + 1]
    end
  rescue
    @track.goals.first
  end

  def on_the_road?(margin: ROAD_MAX_DISTANCE)
    distance_to_road <= margin
  end

  def distance_to_goal
    @position.distance_to(@goal.position)
  end

  def distance_to_road
    @position.distance_to_line(closest_road)
  end

  def closest_road
    @track.roads.min_by { |road| @position.distance_to_line(road) }
  end

  def color
    if finished?
      Gosu::Color::RED
    else
      Gosu::Color::WHITE
    end
  end
end
