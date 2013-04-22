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


  def self.distance(p1, p2)
    x = p2.x - p1.x
    y = p2.y - p1.y
    Math.sqrt(x*x + y*y)
  end
end