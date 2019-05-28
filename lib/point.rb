class Point
  def initialize(x:, y:)
    @x, @y = x, y
  end

  attr_accessor :x, :y

  def draw(size: 1, color: Gosu::Color::WHITE, z: 1)
    $game.draw_rect(@x - size / 2.0, @y - size / 2.0, size, size, color, z)
  end

  def angle_to(point)
    Gosu.angle(x, y, point.x, point.y)
  end

  def distance_to(point)
    Gosu.distance(x, y, point.x, point.y)
  end

  def draw_line_to(point, color = Gosu::Color::WHITE)
    $game.draw_line(x, y, color, point.x, point.y, color)
  end

  def jump(distance, angle)
    dx = Gosu.offset_x(angle % 360.0, distance)
    dy = Gosu.offset_y(angle % 360.0, distance)

    Point.new(x: x + dx, y: y + dy)
  end

  def closest_point_to_line(line)
    delta_x = line.p2.x - line.p1.x + 0.0
    delta_y = line.p2.y - line.p1.y + 0.0

    raise if delta_x.zero? && delta_y.zero?

    u = ((x - line.p1.x) * delta_x + (y - line.p1.y) * delta_y) / (delta_x * delta_x + delta_y * delta_y)

    if u < 0
      Point.new(x: line.p1.x, y: line.p1.y)
    elsif u > 1
      Point.new(x: line.p2.x, y: line.p2.y)
    else
      Point.new(x: line.p1.x + u * delta_x, y: line.p1.y + u * delta_y)
    end
  end

  def distance_to_line(line)
    distance_to(closest_point_to_line(line))
  end

  def to_s
    "(#{x},#{y})"
  end
end
