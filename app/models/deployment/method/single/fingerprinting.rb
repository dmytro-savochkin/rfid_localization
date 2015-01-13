class Deployment::Method::Single::Fingerprinting < Deployment::Method::Single::Base

	# TODO: (maybe)
	# для фингерпринтинга: чем ближе антенны друг к другу - тем меньше к-т на который умножаем

	STEP = 2

	def calculate_result
		ellipses_count = {}
		normalized_ellipses_count = {}
		big_ellipses_count = {}

		(0..@work_zone.width).step(STEP) do |x|
			ellipses_count[x] ||= {}
			normalized_ellipses_count[x] ||= {}
			big_ellipses_count[x] ||= {}
			(0..@work_zone.height).step(STEP) do |y|
				ellipses_count[x][y] = 0
				big_ellipses_count[x][y] = 0
				point = Point.new(x, y)

				@work_zone.antennae.values.each do |antenna|
					if MI::A.point_in_ellipse?(point, antenna, [antenna.big_coverage_zone_width, antenna.big_coverage_zone_height])
						big_ellipses_count[x][y] += 1
					end
				end

				ellipses_count[x][y] = @coverage[x][y]
				if ellipses_count[x][y] == 0
					ellipses_count[x].delete(y)
				end
				if big_ellipses_count[x][y] == 0
					big_ellipses_count[x].delete(y)
				end

				if ellipses_count[x][y]
					normalized_ellipses_count[x][y] = calculate_normalized_value(ellipses_count[x][y])
				end
			end
		end


		three_antennae_covering_area =
				ellipses_count.values.to_a.map{|e| e.values}.flatten.select{|c| c >= 3}.length.to_f
		one_antenna_covering_area =
				ellipses_count.values.to_a.map{|e| e.values}.flatten.select{|c| c >= 1}.length.to_f
		one_antenna_big_covering_area =
				big_ellipses_count.values.to_a.map{|e| e.values}.flatten.select{|c| c >= 1}.length.to_f

		average_result = calculate_average(ellipses_count)
		{
				data: ellipses_count,
				normalized_data: normalized_ellipses_count,
				average_data: average_result,
				normalized_average_data: calculate_normalized_value(average_result),
				three_antennae_covering_area: three_antennae_covering_area,
				one_antenna_covering_area: one_antenna_covering_area,
				one_antenna_big_covering_area: one_antenna_big_covering_area
		}
	end



	private

	def calculate_normalized_value(ellipses_count)
		# four antennae are enough to give very good estimates
		# more antennae almost do not improve accuracy
		max_intersections = 4

		1.0 - [(max_intersections.to_f - ellipses_count), 0].max / max_intersections
	end
end