class Line
  def initialize(p1:,p2:)
    @p1, @p2 = p1, p2
  end

  attr_accessor :p1, :p2
  alias start p1
  alias finish p2

  def angle
    p1.angle_to(p2)
  end

  def length
    p1.distance_to(p2)
  end

  def middle
    Point.new(x: ((p1.x + p2.x) / 2.0) - 1, y: ((p1.y + p2.y) / 2.0) - 1)
  end

  def draw(color = Gosu::Color::WHITE)
    p1.draw_line_to(p2, color)
  end
end
