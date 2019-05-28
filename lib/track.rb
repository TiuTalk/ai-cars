require './lib/point'
require './lib/line'
require './lib/convex_hull'

class Track
  MARGIN = 75
  MIN_POINTS = 10
  MAX_POINTS = 100
  MIN_DISTANCE = 50
  GOALS_PER_ROAD = 3

  def initialize
    @points = generate_points
    @roads = generate_roads
    @goals = generate_goals
    @label = Gosu::Font.new(11)
  end

  attr_reader :goals, :roads

  def start
    @points.first
  end

  def start_angle
    @roads.first.angle
  end

  def draw
    @roads.each.with_index { |road, i| road.draw(@label, i) }
    @goals.each(&:draw)
  end

  def start_drag(window)
    return unless mouse_within_window?(window)

    point = @points.sort_by do |p|
      p.distance_to(Point.new(x: window.mouse_x, y: window.mouse_y))
    end.first

    @draggable_point = @points.index(point)
  end

  def update_drag(window)
    return unless mouse_within_window?(window)

    @points[@draggable_point].x = window.mouse_x
    @points[@draggable_point].y = window.mouse_y

    @roads = generate_roads
    @goals = generate_goals
  end

  def end_drag(window)
    return unless mouse_within_window?(window)

    @draggable_point = nil
  end

  private

  def mouse_within_window?(window)
    window.mouse_x >= 0 && window.mouse_x <= Game::WIDTH &&
      window.mouse_y >= 0 && window.mouse_y <= Game::HEIGHT
  end

  def generate_points
    points = Array.new(rand(MIN_POINTS..MAX_POINTS)) do
      x = rand(MARGIN..Game::WIDTH-MARGIN)
      y = rand(MARGIN..Game::HEIGHT-MARGIN)

      Point.new(x: x, y: y)
    end.sort_by(&:x).uniq

    points = ConvexHull.calculate(points).uniq.reverse
    3.times { points = push_points_apart(points) }
    points
  end

  def push_points_apart(points)
    dst2 = MIN_DISTANCE ** 2

    points.each.with_index do |p1, i|
      points[i + 1..-1].each.with_index(i + 1) do |p2, j|
        next if p1.distance_to(p2) ** 2 >= dst2

        hx = p2.x - p1.x + 0.0
        hy = p2.y - p1.y + 0.0
        hl = Math.sqrt(hx * hx + hy * hy)
        hx /= hl
        hy /= hl

        dif = MIN_DISTANCE - hl
        hx *= dif
        hy *= dif
        p2.x += hx
        p2.y += hy
        p1.x -= hx
        p1.y -= hy

        points[i] = p1
        points[j] = p2
      end
    end

    points
  end

  def generate_roads
    roads = []

    @points.each_cons(2) do |p1, p2|
      roads << Road.new(p1: p1, p2: p2)
    end

    roads << Road.new(p1: @points.last, p2: @points.first)

    roads
  end

  def generate_goals
    @roads.reduce([]) do |goals, road|
      goals += generate_goals_for_road(road)
    end
  end

  def generate_goals_for_road(road)
    goals = []

    step = road.length / (GOALS_PER_ROAD + 2)

    GOALS_PER_ROAD.times do |i|
      distance = step * (i + 1)
      goals << Goal.new(position: road.start.jump(distance, road.angle))
    end

    goals << Goal.new(position: road.finish)

    goals
  end

  # def draw_road(p1, p2)
  #   draw_road_side(p1, p2, -30)
  #   draw_road_side(p1, p2, +30)
  # end

  # def draw_road_side(p1, p2, offset)
  #   l = Math.sqrt((p1.x - p2.x)**2 + (p1.y - p2.y)**2)

  #   rs1 = Point.new(x: p1.x + offset * (p2.y - p1.y) / l, y: p1.y + offset * (p1.x - p2.x) / l)
  #   rs2 = Point.new(x: p2.x + offset * (p2.y - p1.y) / l, y: p2.y + offset * (p1.x - p2.x) / l)

  #   rs1.draw_line_to(rs2, Gosu::Color::BLUE)
  # end
  class Road < Line
    def draw(label, number)
      super()
      label.draw_text(number, start.x + 10, start.y + 5, 10, 1, 1, Gosu::Color::GREEN)
    end
  end

  class Goal
    def initialize(position: position)
      @position = position
    end

    attr_reader :position

    def draw
      $game.draw_rect(@position.x, @position.y, 3, 3, Gosu::Color::YELLOW)
    end
  end
end
