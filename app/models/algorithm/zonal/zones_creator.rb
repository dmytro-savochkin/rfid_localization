class Algorithm::Zonal::ZonesCreator
  attr_reader :zones

  def initialize(work_zone, mode, coverage_zone_width, coverage_zone_height, step = 5)
    @work_zone = work_zone
    @mode = mode
    @step = step
    @coverage_zone_width = coverage_zone_width
    @coverage_zone_height = coverage_zone_height
    @zones = create_zones
  end



  def create_zones
    zones = {}
    zones_points = {}

    (0..@work_zone.width).step(@step) do |x|
      (0..@work_zone.height).step(@step) do |y|
        point = Point.new(x, y)

        active_antennas = []
        1.upto(16) do |antenna_number|
          antenna = Antenna.new antenna_number
          active_antennas.push antenna_number if point_in_antenna_coverage?(point, antenna)
        end

        zones_points[active_antennas.to_s] ||= []
        zones_points[active_antennas.to_s].push point
      end
    end

    zones_points.each do |antenna_combination, points|
      zones[antenna_combination] = Point.center_of_points points
    end

    zones
  end




  def point_in_antenna_coverage?(point, antenna)
    return point_in_ellipse?(point, antenna) if @mode == :ellipses
    return point_in_rectangle?(point, antenna) if @mode == :rectangles
    false
  end

  def point_in_ellipse?(point, antenna)
    x = point.x
    cx = antenna.coordinates.x
    cy = antenna.coordinates.y
    aa = @coverage_zone_width ** 2
    bb = @coverage_zone_height ** 2
    fi = Math::PI / 4
    sin_fi = Math.sin(fi)
    cos_fi = Math.cos(fi)

    part1 = sin_fi * (cx - x) - cy * cos_fi
    part2 = cos_fi * (cx - x) + cy * sin_fi

    a = (sin_fi ** 2) / aa + (cos_fi ** 2) / bb
    b = ((2 * cos_fi * part1) / bb) - ((2 * sin_fi * part2) / aa)
    c = ((part2 ** 2) / aa) + ((part1 ** 2) / bb) - 1

    discriminant = b ** 2 - 4*a*c

    if discriminant >= 0
      e2_y_up = (-b + Math.sqrt(discriminant)) / (2*a)
      e2_y_down = (-b - Math.sqrt(discriminant)) / (2*a)
      ! (point.y >= e2_y_up || point.y <= e2_y_down)
    else
      false
    end
  end

  def point_in_rectangle?(point, antenna)
    fi = Math::PI / 4
    sin_fi = Math.sin(fi)
    cos_fi = Math.cos(fi)

    cx = antenna.coordinates.x
    cy = antenna.coordinates.y

    rotated_point = Point.new(
        cx + cos_fi * (point.x - cx) - sin_fi * (point.y - cy),
        cy + sin_fi * (point.x - cx) + cos_fi * (point.y - cy)
    )

    left_x = cx - @coverage_zone_width/2
    right_x = cx + @coverage_zone_width/2
    top_y = cy - @coverage_zone_height/2
    bottom_y = cy + @coverage_zone_height/2

    (left_x <= rotated_point.x and rotated_point.x <= right_x and
      top_y <= rotated_point.y and rotated_point.y <= bottom_y)
  end
end