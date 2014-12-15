class MI::A < Algorithm::Base
	require "inline"
	class CCode
		inline do |builder|
			builder.c "
			  int is_point_in_ellipse(double point_x, double point_y, double antenna_x, double antenna_y, double coverage_width, double coverage_height, double rotation) {
					if(coverage_width == coverage_height) {
						if( (pow((point_x-antenna_x), 2) + pow((point_y-antenna_y), 2)) <= pow((coverage_width/2),2)) {
							return 1;
						}
						else {
							return 0;
						}
					}

					double fi = rotation;
					double sin_fi = sin(fi);
					double cos_fi = cos(fi);

					double aa = pow(coverage_width/2, 2);
					double bb = pow(coverage_height/2, 2);

					double cxx = antenna_x-point_x;
					double part1 = sin_fi * cxx - antenna_y * cos_fi;
					double part2 = cos_fi * cxx + antenna_y * sin_fi;
		      double a = pow(sin_fi, 2) / aa + pow(cos_fi, 2) / bb;
					double b = ((2 * cos_fi * part1) / bb) - ((2 * sin_fi * part2) / aa);
					double c = (pow(part2, 2) / aa) + (pow(part1, 2) / bb) - 1;

					double discriminant = pow(b, 2) - 4*a*c;

					if(discriminant >= 0) {
						double e2_y_up = (-b + sqrt(discriminant)) / (2*a);
						double e2_y_down = (-b - sqrt(discriminant)) / (2*a);
						return (! (point_y >= e2_y_up || point_y <= e2_y_down));
					} else {
						return 0;
					}
				}
			"
		end
	end


	def initialize(a, reader_power)
    @a = a
    @reader_power = reader_power
  end






  class << self
    def point_in_ellipse?(point, antenna, antennae_size, c_instance = CCode.new)
			c_instance.is_point_in_ellipse(
					point.x,
					point.y,
					antenna.coordinates.x,
					antenna.coordinates.y,
					antennae_size[0],
					antennae_size[1],
					antenna.rotation
			).to_b
			#x = point.x
			#cx = antenna.coordinates.x
			#cy = antenna.coordinates.y
			#aa = antenna.coverage_zone_width ** 2
			#bb = antenna.coverage_zone_height ** 2
			#
			#if antenna.coverage_zone_width == antenna.coverage_zone_height
			#	if ((point.x-cx)**2 + (point.y-cy)**2) <= (antenna.coverage_zone_width/2)**2
			#		return true
			#	else
			#		return false
			#	end
			#end
			#
			#fi = Math::PI / 4
			#sin_fi = Math.sin(fi)
			#cos_fi = Math.cos(fi)
			#
			#part1 = sin_fi * (cx - x) - cy * cos_fi
			#part2 = cos_fi * (cx - x) + cy * sin_fi
			#
			#a = (sin_fi ** 2) / aa + (cos_fi ** 2) / bb
			#b = ((2 * cos_fi * part1) / bb) - ((2 * sin_fi * part2) / aa)
			#c = ((part2 ** 2) / aa) + ((part1 ** 2) / bb) - 1
			#
			#discriminant = b ** 2 - 4*a*c
			#
			#if discriminant >= 0
       # e2_y_up = (-b + Math.sqrt(discriminant)) / (2*a)
       # e2_y_down = (-b - Math.sqrt(discriminant)) / (2*a)
       # ! (point.y >= e2_y_up || point.y <= e2_y_down)
			#else
       # false
			#end
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