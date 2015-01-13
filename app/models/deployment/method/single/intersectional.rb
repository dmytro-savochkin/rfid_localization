class Deployment::Method::Single::Intersectional < Deployment::Method::Single::Base
	class NoEstimate < Exception
	end

	STEP = 4
	MODE = :probabilistic

	def initialize(work_zone, coverage = nil, coverage_in_center = nil)
		super
		@mi_base_c_code = MI::Base::CCode.new
		@point_c_code = Point::CCode.new
	end

	def make_preparation
		@zones_creator = Algorithm::PointBased::Zonal::ZonesCreator.new(
				@work_zone, :ellipses, STEP
		)
		@zones = @zones_creator.create_elementary_zones
		@zones_centers = @zones_creator.elementary_zones_centers(@zones)
		@zones_as_s = Hash[ @zones.map{|a, points| [a, points.map{|p| p.to_s}]} ]
	end




	def calculate_result
		error = {}
		normalized_error = {}
		estimates = {}

		@zones.each do |antenna_combination, zone|
		  zone.each do |point|
				if antenna_combination != '[]'
					x = point.x.to_i
					y = point.y.to_i
					estimates[x] ||= {}
					error[x] ||= {}
					normalized_error[x] ||= {}
					current_estimates, current_error =
							calculate_estimates_and_error(point, antenna_combination)
					estimates[x][y] = current_estimates
					error[x][y] = current_error
					normalized_error[x][y] = calculate_normalized_value(error[x][y])
				end
			end
		end


		average_error = calculate_average(error)
		{
				data: error,
				normalized_data: normalized_error,
				average_data: average_error,
				normalized_average_data: calculate_normalized_value(average_error),
				estimates: estimates
		}
	end




	private

	def calculate_estimates_and_error(point, antenna_combination)
		estimates = []

		if MODE == :deterministic
			estimates.push([@zones_centers[antenna_combination], 1.0])
			error = Point.distance(point, @zones_centers[antenna_combination], @point_c_code)
		elsif MODE == :probabilistic
			active_antennas = {small: [], big: []}
			@work_zone.antennae.each do |antenna_number, antenna|
				if @zones_creator.point_in_antenna_coverage?(point, antenna, :min)
					active_antennas[:small].push antenna_number
				else
					if @zones_creator.point_in_antenna_coverage?(point, antenna, :max)
						active_antennas[:big].push antenna_number
					end
				end
			end

			bl = active_antennas[:big].length
			big_combinations =
					(1..bl).to_a.map{|n| active_antennas[:big].to_a.combination(n).to_a}.flatten(1) + [[]]

			error = 0.0

			big_combinations.each do |big_combination|
				probability = 1.0

				calc_combination_probability = lambda do |combination, type|
					result_probability = 1.0
					combination.each do |antenna_number|
						antenna = @work_zone.antennae[antenna_number]
						d = Point.distance(point, @work_zone.antennae[antenna_number].coordinates, @point_c_code)
						angle = @work_zone.antennae[antenna_number].coordinates.angle_to_point(point)
						probability = response_probability(antenna, d, angle)
						if type == :responded
							result_probability *= probability
						elsif type == :not_responded
							result_probability *= 1.0 - probability
						else
							raise ArgumentError.new("Wrong type #{type}")
						end
					end
					result_probability
				end

				probability *= calc_combination_probability.call(big_combination, :responded)
				probability *= calc_combination_probability.call(active_antennas[:big] - big_combination, :not_responded)

				estimate = zone_estimate(big_combination + active_antennas[:small])
				if estimate.nil?
					combination_error = (WorkZone::WIDTH + WorkZone::HEIGHT) / 2
				else
					combination_error = Point.distance(point, estimate, @point_c_code)
				end
				estimates.push [estimate, probability]
				error += probability * combination_error
			end
		else
			raise Exception.new("Mode #{MODE} is not supported")
		end

		[estimates, error]
	end








	def zone_estimate(combination)
		sorted_combination = combination.sort
		if sorted_combination.empty?
			nil
		elsif @zones_centers[sorted_combination.to_s] != nil
			@zones_centers[sorted_combination.to_s]
		else
			Point.center_of_points(
					@work_zone.
							antennae.
							select{|n,a| sorted_combination.include? n}.
							values.
							map{|a| a.coordinates}
			)
		end
	end


	def response_probability(antenna, d, fi)
		min = MI::Base.ellipse(
				fi,
				antenna.coverage_zone_ratio,
				antenna.coverage_zone_height,
				antenna.rotation,
				@mi_base_c_code
		) / 2
		max = MI::Base.ellipse(
				fi,
				antenna.big_coverage_zone_ratio,
				antenna.big_coverage_zone_height,
				antenna.rotation,
				@mi_base_c_code
		) / 2

		if d < min
			1.0
		elsif d < max and d >= min
			1.0 - (d - min) / (max - min)
		else
			0.0
		end
	end


	def calculate_normalized_value(error)
		# as (500 - 70*2) / 3 where 70 is a shift and 3 is
		# the count of intervals between antennae in a row
		max_error = 60.0

		1.0 - ([error, max_error].min / max_error)
	end
end
