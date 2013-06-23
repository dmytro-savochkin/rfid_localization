class MeasurementInformation::A < Algorithm::Base
  def initialize(a, reader_power)
    @a = a
    @reader_power = reader_power
  end


  class << self

    def point_in_ellipse?(point, antenna)
      x = point.x
      cx = antenna.coordinates.x
      cy = antenna.coordinates.y
      aa = antenna.coverage_zone_width ** 2
      bb = antenna.coverage_zone_height ** 2
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

      left_x = cx - antenna.coverage_zone_width / 2
      right_x = cx + antenna.coverage_zone_width / 2
      top_y = cy - antenna.coverage_zone_height / 2
      bottom_y = cy + antenna.coverage_zone_height / 2

      (left_x <= rotated_point.x and rotated_point.x <= right_x and
          top_y <= rotated_point.y and rotated_point.y <= bottom_y)
    end

  end
end