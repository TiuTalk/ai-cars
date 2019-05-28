# Computes the convex hull of a set of 2D points.

# Input: an iterable sequence of (x, y) pairs representing the points.
# Output: a list of vertices of the convex hull in counter-clockwise order,
# starting from the vertex with the lexicographically smallest coordinates.
# Implements Andrew's monotone chain algorithm. O(n log n) complexity.

class ConvexHull
  def self.calculate(points)
    # Boring case: no points or a single point, possibly repeated multiple times.
    return points if points.length <= 3

    lower = upper = []

    # Build lower hull
    points.each do |point|
      lower.pop while lower.length >= 2 && cross(lower[-2], lower[-1], point) <= 0
      lower.push(point)
    end

    # Build upper hull
    points.reverse_each do |point|
      upper.pop while upper.length >= 2 && cross(upper[-2], upper[-1], point) <= 0
      upper.push(point)
    end

    # Concatenation of the lower and upper hulls gives the convex hull.
    # Last point of each list is omitted because it is repeated at the beginning of the other list.
    lower[0...-1] + upper[0...-1]
  end

  # 2D cross product of OA and OB vectors, i.e. z-component of their 3D cross product.
  # Returns a positive value, if OAB makes a counter-clockwise turn,
  # negative for clockwise turn, and zero if the points are collinear.
  def self.cross(o, a, b)
    (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
  end
end
