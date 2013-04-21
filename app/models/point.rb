class Point
  attr_reader :x, :y

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
end