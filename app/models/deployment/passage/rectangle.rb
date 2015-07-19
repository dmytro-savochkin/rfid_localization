class Deployment::Passage::Rectangle < Deployment::Passage::Base
	attr_reader :full_area, :full_area_in_center

	def initialize(center, width, height)
		#@c_code = CCode.new
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


end