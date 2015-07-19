class Deployment::Obstruction::Rectangle < Deployment::Obstruction::Base
	require "inline"

	class CCode
		inline do |builder|
			builder.c "
				int triangle_area(double ax, double ay, double bx, double by, double cx, double cy) {
					return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
				}
			"
			builder.c "
				int intersect_1(int a, int b, int c, int d) {
					int temp, max_ac, max_bd;
					if (a > b) {
							temp = a; a = b; b = temp;
					}
					if (c > d) {
							temp = c; c = d; d = temp;
					}
					if(a>c){max_ac = a;}
					else max_ac = c;
					if(b>d){max_bd = b;}
					else max_bd = d;
					return max_ac <= max_bd;
				}
			"
		end
	end





	attr_reader :full_area, :full_area_in_center

	def initialize(center, width, height)
		@c_code = CCode.new
		@point_c_code = Point::CCode.new

		@center = center
		@width = width.to_f
		@height = height.to_f

		@corners = [
				Point.new(@center.x - @width/2, @center.y - @height/2),
				Point.new(@center.x - @width/2, @center.y + @height/2),
				Point.new(@center.x + @width/2, @center.y + @height/2),
				Point.new(@center.x + @width/2, @center.y - @height/2)
		]

		@full_area = @width * @height
		@full_area_in_center = intersection_area_with_center_field
	end


	def are_points_blocked?(p1, p2)
		@corners.each_with_index do |corner, i|
			next_index = i + 1
			next_index = 0 if i == 3
			next_corner = @corners[next_index]
			p3 = corner
			p4 = next_corner
			return true if do_segments_intersect([p1, p2], [p3, p4])
		end
		false
	end

	def point_inside?(point)
		point.inside_rectangle(@corners.first, @width, @height, @point_c_code)
	end


	private

	def intersection_area_with_center_field
		x11 = @corners[0].x
		y11 = @corners[0].y
		x12 = @corners[2].x
		y12 = @corners[2].y

		x21 = Deployment::Method::Base::CENTER_SHIFT
		y21 = Deployment::Method::Base::CENTER_SHIFT
		x22 = WorkZone::WIDTH.to_f - Deployment::Method::Base::CENTER_SHIFT
		y22 = WorkZone::HEIGHT.to_f - Deployment::Method::Base::CENTER_SHIFT

		x_overlap = [0.0, [x12,x22].min - [x11,x21].max].max
		y_overlap = [0.0, [y12,y22].min - [y11,y21].max].max

		x_overlap * y_overlap
	end

	def do_segments_intersect(line1, line2)
		a = line1[0]
		b = line1[1]
		c = line2[0]
		d = line2[1]
		@c_code.intersect_1(a.x, b.x, c.x, d.x) &&
			@c_code.intersect_1(a.y, b.y, c.y, d.y) &&
			@c_code.triangle_area(a.x, a.y, b.x, b.y, c.x, c.y) * @c_code.triangle_area(a.x, a.y, b.x, b.y, d.x, d.y) <= 0 &&
			@c_code.triangle_area(c.x, c.y, d.x, d.y, a.x, a.y) * @c_code.triangle_area(c.x, c.y, d.x, d.y, b.x, b.y) <= 0
	end

end
