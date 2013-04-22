class Point
  attr_accessor :x, :y

  def initialize(x, y)
    @x = x
    @y = y
  end

  def rotate(angle)
    hyp = Math.sqrt(@x**2 + @y**2)
    angle = Math.atan2(@y, @x) + angle
    @x = hyp*Math.cos(angle)
    @y = hyp*Math.sin(angle)
  end

  def shift(x, y)
    @x += x
    @y += y
  end

  def to_a
    [@x, @y]
  end


  def self.distance(p1, p2)
    x = p2.x - p1.x
    y = p2.y - p1.y
    Math.sqrt(x*x + y*y)
  end

  def self.center_of_points(points, weights = [])
    weights = Array.new(points.size, 1.0/points.size) if weights.empty?

    center = Point.new 0, 0
    points.each_with_index do |point, index|
      center.x += (point.x * weights[index])
      center.y += (point.y * weights[index])
    end
    center
  end
end