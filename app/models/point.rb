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

  def zero?
    return true if @x == 0.0 and @y == 0.0
    false
  end

  def to_a
    [@x, @y]
  end

  def to_s
    @x.to_f.to_s + "-" + @y.to_f.to_s
  end



  def within_tags_boundaries?
    return true if
        @x >= TagInput::START and @x <= (WorkZone::WIDTH - TagInput::START) and
        @y >= TagInput::START and @y <= (WorkZone::HEIGHT - TagInput::START)
    false
  end


  def nearest_tags_coords
    start = TagInput::START.to_f
    step = TagInput::STEP.to_f

    lower_bound = start
    upper_bound = WorkZone::WIDTH - start

    tags_coords = []


    before = ->(coord) do
      ([(coord.to_f - start), 0.0].max / step).floor * step + start
    end
    after = ->(coord) do
      return start.to_f if coord.to_f == 0.0
      ([(coord.to_f - start), 0.0].max / step).ceil * step + start
    end



    [before.call(@x), after.call(@x)].each do |x|
      [before.call(@y), after.call(@y)].each do |y|
        if x >= lower_bound and x <= upper_bound and y >= lower_bound and y <= upper_bound
          tags_coords.push(x.to_s + '-' + y.to_s)
        end
      end
    end

    tags_coords.uniq
  end


  def select_nearest_points(points)
    points_to_find_nearest = []
    points_to_find_nearest.push points.select{|p| p.y >= y and p.x <= x}
    points_to_find_nearest.push points.select{|p| p.y >= y and p.x > x}
    points_to_find_nearest.push points.select{|p| p.y < y and p.x <= x}
    points_to_find_nearest.push points.select{|p| p.y < y and p.x > x}

    nearest_points = []

    points_to_find_nearest.each do |point_group|
      nearest_points.push( point_group.sort_by{|p| Point.distance(self, p)}.first )
    end

    nearest_points.reject(&:nil?)
  end


  def approximation_proximity_coeffs(points)
    distances = []
    points.each{|p| distances.push(Point.distance(self, p))}
    coeffs = []
    inverted_distances_sum = distances.map{|d| 1.0 / d }.sum
    distances.each{|distance| coeffs.push( (1.0 / distance) / inverted_distances_sum )}
    coeffs
  end



  def angle_to_point(point)
    Math.atan2(point.y - self.y, point.x - self.x)
  end

  def distance_to_point(point)
    Math.sqrt((self.y - point.y) ** 2 + (self.x - point.x) ** 2)
  end


  def in_zone?(zone_number)
    zone_size = WorkZone::WIDTH.to_f / 4
    zone_center = Zone.new(zone_number).coordinates
    if x >= (zone_center.x - zone_size / 2) and x <= (zone_center.x + zone_size / 2) and
        y >= (zone_center.y - zone_size / 2) and y <= (zone_center.y + zone_size / 2)
      return true
    end
    false
  end



  def zone
    zones = (1..16).to_a.map{|zone_number| Zone.new(zone_number)}
    zones.sort_by{|zone| Point.distance(zone.coordinates, self)}.first
  end


  def shortest_distance_to_zone_border(zone_number)
    zone = Zone.new(zone_number)
    raise Exception.new('point inside the zone') if self.in_zone?(zone_number)

    zone_center = zone.coordinates
    zone_size = zone.size

    top_y = zone_center.y + zone.size / 2
    bottom_y = zone_center.y - zone.size / 2
    left_x = zone_center.x - zone.size / 2
    right_x = zone_center.x + zone.size / 2

    if self.y > top_y
      if self.x < left_x
        zone_nearest_point = Point.new(zone_center.x - zone_size/2, zone_center.y + zone_size/2)
      elsif self.x > left_x
        zone_nearest_point = Point.new(zone_center.x + zone_size/2, zone_center.y + zone_size/2)
      else
        zone_nearest_point = Point.new(self.x, zone_center.y + zone_size/2)
      end
    elsif self.y < bottom_y
      if self.x < left_x
        zone_nearest_point = Point.new(zone_center.x - zone_size/2, zone_center.y - zone_size/2)
      elsif self.x > left_x
        zone_nearest_point = Point.new(zone_center.x + zone_size/2, zone_center.y - zone_size/2)
      else
        zone_nearest_point = Point.new(self.x, zone_center.y - zone_size/2)
      end
    else
      if self.x < left_x
        zone_nearest_point = Point.new(zone_center.x - zone_size/2, self.y)
      elsif self.x > right_x
        zone_nearest_point = Point.new(zone_center.x + zone_size/2, self.y)
      else
        raise Exception.new('this situation can\' be reached')
      end
    end

    Point.distance(self, zone_nearest_point)
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


  def self.spatial_distance_from_antenna(antenna, point)
    height = WorkZone::ROOM_HEIGHT
    Math.sqrt(height ** 2 + distance(antenna.coordinates, point) ** 2)
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




  def self.sort_polygon_vertices(polygon)
    return nil if polygon.any?{|point| ! point.is_a?(Point)}
    center = Point.center_of_points(polygon)
    polygon.sort_by{|vertex| Math.atan2(vertex.y - center.y, vertex.x - center.x)}
  end


  def self.points_in_polygon(polygon, step = 1.0)
    return nil if polygon.any?{|vertex| ! vertex.is_a?(Point)}
    step = step.to_f

    polygon = sort_polygon_vertices(polygon)

    min_y = polygon.map{|vertex| vertex.y}.min
    max_y = polygon.map{|vertex| vertex.y}.max

    x_boundaries = {}
    (min_y..max_y).step(step) do |y|
      x_boundaries[y] = {:min => WorkZone::WIDTH.to_f, :max => 0.0}
    end


    polygon.each_with_index do |vertex, i|
      next_vertex = polygon[i + 1]
      next_vertex = polygon[0] if next_vertex.nil?

      all_points_through_vertices_line = []
      start_y = [vertex.y, next_vertex.y].min
      end_y = [vertex.y, next_vertex.y].max
      (start_y..end_y).step(step) do |y|
        x = (y - vertex.y) / (next_vertex.y - vertex.y) * (next_vertex.x - vertex.x) + vertex.x
        x = vertex.x if x.nan?
        all_points_through_vertices_line.push Point.new(x, y)
      end


      #puts start_y.to_s + ' and ' + end_y.to_s
      #puts vertex.to_s + ' and ' + next_vertex.to_s
      #puts all_points_through_vertices_line.to_s
      #puts ''
      #
      #puts x_boundaries.to_s

      all_points_through_vertices_line.each do |point|
        #puts 'this'+ point.y.to_s + '  ' + x_boundaries[point.y].to_s + ' ' + point.to_s
        x_boundaries[point.y][:max] = point.x if point.x > x_boundaries[point.y][:max]
        x_boundaries[point.y][:min] = point.x if point.x < x_boundaries[point.y][:min]
      end

      #puts x_boundaries.to_s
      #puts ''
      #puts ''
      #puts ''
    end



    #puts 'boundary: ' + x_boundaries.to_s


    points = []
    x_boundaries.each do |y, x_boundary|
      (x_boundary[:min]..x_boundary[:max]).step(step) do |x|
        points.push Point.new(x, y)
      end
    end

    points
  end
end





