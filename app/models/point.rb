class Point
  attr_accessor :x, :y

  def initialize(x, y)
    @x = x.to_f
    @y = y.to_f
  end

  def rotate(angle)
    hyp = Math.sqrt(@x**2 + @y**2)
    angle = Math.atan2(@y, @x) + angle
    @x = hyp*Math.cos(angle)
    @y = hyp*Math.sin(angle)
  end

  def shift(x, y)
    @x += x.to_f
    @y += y.to_f
  end

  def nil?
    return true if @x.nil? or @y.nil?
    false
  end

  def to_a
    [@x, @y]
  end

  def to_s
    @x.to_f.to_s + "-" + @y.to_f.to_s
  end



  def angle_to_point(point)
    Math.atan2(point.y - self.y, point.x - self.x)
  end

  def distance_to_point(point)
    Math.sqrt((self.y - point.y) ** 2 + (self.x - point.x) ** 2)
  end

  def self.from_a(coords_array)
    self.new(*coords_array.to_a)
  end

  def self.from_s(coords)
    coords_array = coords.split('-').map(&:to_f)
    coords_array = [nil, nil] if coords_array[0] == 0 and coords_array[1] == 0
    self.new(*coords_array)
  end

  def self.coords_correct?(x, y)
    return true if x >= 0 and x <= WorkZone::WIDTH and y >= 0 and y <= WorkZone::HEIGHT
    false
  end

  def self.distance(p1, p2)
    return nil if p1.nil? or p2.nil? or p1.x.nil? or p1.y.nil? or p2.x.nil? or p2.y.nil?
    x = p2.x - p1.x
    y = p2.y - p1.y
    Math.sqrt(x*x + y*y)
  end

  def self.center_of_points(points, weights = [])
    if weights.empty?
      weights = Array.new(points.size, 1.0/points.size)
    else
      weights_sum = weights.sum
      weights = weights.map{|w| w / weights_sum} if weights_sum > 1.0
    end

    center = Point.new 0.0, 0.0
    points.each_with_index do |point, index|
      center.x += (point.x * weights[index])
      center.y += (point.y * weights[index])
    end
    center
  end
end