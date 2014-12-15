class Regression::Deviations
	def initialize
		@ellipse_ratio = 1.0
		@degrees_sets = [
				[1.0, 2.0, 3.0],
				[1.0, 2.0],
		]


		@coeffs = {}
		@angle_coeff = {}
		@mi_range = {}
		@mi_range_center = {}
		(20..30).each do |reader_power|
			@coeffs[reader_power] ||= {}
			@angle_coeff[reader_power] ||= {}
			@mi_range[reader_power] ||= {}
			@mi_range_center[reader_power] ||= {}
			@degrees_sets.each do |degrees_set|
				max_degree = degrees_set.max.to_f
				@coeffs[reader_power][max_degree], @angle_coeff[reader_power][max_degree] =
						get_model(max_degree, reader_power)
				@mi_range[reader_power][max_degree] =
						Regression::MiBoundary.where(:type => :rss, :reader_power => reader_power).first
				@mi_range_center[reader_power][max_degree] =
						@mi_range[reader_power][max_degree].max.to_f -
						(@mi_range[reader_power][max_degree].max.to_f -
						@mi_range[reader_power][max_degree].min.to_f) / 2
			end
		end


	end




	def calculate_for_antennas
		stddevs = {}
		@degrees_sets.each do |degrees_set|
			max_degree = degrees_set.max.to_f
			stddevs[max_degree] = {}
			deviations = []
			(1..16).each do |antenna_number|
				puts antenna_number.to_s
				errors = []
				(20..30).to_a.each do |reader_power|
					MI::Base::HEIGHTS.each do |height|
						errors.push(calculate_errors(max_degree, reader_power, antenna_number, height))
					end
				end
				stddevs[max_degree][antenna_number] = errors.flatten.stddev
				deviations.push errors.flatten.stddev
			end
			stddevs[max_degree][:stddev] = deviations.stddev
			stddevs[max_degree][:mean] = deviations.mean
		end
		stddevs
	end

	def calculate_for_reader_powers
		stddevs = {}
		@degrees_sets.each do |degrees_set|
			max_degree = degrees_set.max.to_f
			stddevs[max_degree] = {}
			deviations = []
			(20..30).to_a.each do |reader_power|
				stddevs[max_degree][reader_power] ||= {}
				puts reader_power.to_s
				errors = {:total => []}
				(1..16).each do |antenna_number|
					MI::Base::HEIGHTS.each do |height|
						errors[height] ||= []
						current_errors = calculate_errors(max_degree, reader_power, antenna_number, height)
						errors[height] << current_errors
						errors[:total] << current_errors
					end
				end
				MI::Base::HEIGHTS.each do |height|
					stddevs[max_degree][reader_power][height] = errors[height].flatten.stddev
				end
				stddevs[max_degree][reader_power][:total] = errors[:total].flatten.stddev
				deviations.push errors[:total].flatten.stddev
			end
			stddevs[max_degree][:stddev] = deviations.stddev
			stddevs[max_degree][:mean] = deviations.mean
		end
		stddevs
	end


	def calculate_for_time_random
		stddevs = {}
		angle = -Math::PI/4
		@degrees_sets.each do |degrees_set|
			max_degree = degrees_set.max.to_f
			stddevs[max_degree] = {}

			tags_data = Parser::parse_time_tag_responses
			errors = {}

			tags_data[:by_distance].each do |reader_power, rp_tags_data|
				puts 'rp:' + reader_power.to_s
				rp_tags_data.each do |time, time_tags_data|
					errors[time] ||= []
					stddevs[max_degree][time] ||= []
					puts 'time:' + time.to_s
					time_tags_data.each do |distance, real_rss|
						regression_rss = MI::Rss.regression_root(
								@ellipse_ratio,
								angle,
								distance,
								[@mi_range[reader_power][max_degree].min.to_f, @mi_range[reader_power][max_degree].max.to_f],
								@mi_range_center[reader_power][max_degree],
								@coeffs[reader_power][max_degree],
								@angle_coeff[reader_power][max_degree]
						)
						error = real_rss - regression_rss
						errors[time] << error
					end
				end
			end

			tags_data[:by_distance].values.first.keys.each do |time|
				stddevs[max_degree][time] = errors[time].stddev
			end

			stddevs[max_degree][:stddev] = stddevs[max_degree].values.stddev
			stddevs[max_degree][:mean] = stddevs[max_degree].values.mean
		end

		stddevs
	end


	def calculate_for_position_random
		stddevs = {}
		errors = {}
		@degrees_sets.each do |degrees_set|
			max_degree = degrees_set.max.to_f
			stddevs[max_degree] = {}
			errors[degrees_set] = {}
			(20..30).to_a.each do |reader_power|
				puts reader_power.to_s
				(1..16).each do |antenna_number|
					MI::Base::HEIGHTS.each do |height|
						mi_map = parse_for_antenna_mi_data(antenna_number, height, reader_power)
						data = create_regression_arrays(antenna_number, mi_map, max_degree)
						data[:distances].each_with_index do |distance, i|
							errors[degrees_set][data[:positions][i]] ||= []
							real_mi = data[:mi][1][i].to_f
							angle = data[:angles][i]
							regression_mi = MI::Rss.regression_root(
									@ellipse_ratio,
									angle,
									distance,
									[@mi_range[reader_power][max_degree].min.to_f, @mi_range[reader_power][max_degree].max.to_f],
									@mi_range_center[reader_power][max_degree],
									@coeffs[reader_power][max_degree],
									@angle_coeff[reader_power][max_degree]
							)
							error = real_mi - regression_mi
							errors[degrees_set][data[:positions][i]] << error
						end
					end
				end
			end

			errors[degrees_set].each do |position, errors|
				stddevs[max_degree][position] = errors.stddev
			end
			stddevs[max_degree][:stddev] = stddevs[max_degree].values.stddev
			stddevs[max_degree][:mean] = stddevs[max_degree].values.mean
		end
		stddevs
	end










	private

	def get_model(max_degree, reader_power)
		type = 'powers=' + (1..max_degree).to_a.join(',') + '__ellipse=' + @ellipse_ratio.to_s

		model = Regression::DistancesMi.where(
				:height => 'all',
				:reader_power => reader_power,
				:antenna_number => 'all',
				:type => type,
				:mi_type => :rss
		).first

		parsed_coeffs = JSON.parse(model.mi_coeff)
		coeffs = []
		coeffs[0] = model.const.to_f
		parsed_coeffs.each do |k, mi_coeff|
			unless mi_coeff.nil?
				coeffs.push mi_coeff.to_f
			end
		end
		angle_coeff = model.angle_coeff
		[coeffs, angle_coeff.to_f]
	end

	def calculate_errors(max_degree, reader_power, antenna_number, height)
		errors = []

		mi_map = parse_for_antenna_mi_data(antenna_number, height, reader_power)
		data = create_regression_arrays(antenna_number, mi_map, max_degree)

		data[:distances].each_with_index do |distance, i|
			real_mi = data[:mi][1][i].to_f
			angle = data[:angles][i]

			regression_mi = MI::Rss.regression_root(
					@ellipse_ratio,
					angle,
					distance,
					[
							@mi_range[reader_power][max_degree].min.to_f,
							@mi_range[reader_power][max_degree].max.to_f
					],
					@mi_range_center[reader_power][max_degree],
					@coeffs[reader_power][max_degree],
					@angle_coeff[reader_power][max_degree]
			)

			errors.push(real_mi - regression_mi)
		end

		errors.sort
	end




	def parse_for_antenna_mi_data(antenna, height, reader_power)
		mi_map = {}
		tags = MI::Base.parse_specific_tags_data(height, reader_power)
		tags.values.each do |tag|
			tag.answers[:rss][:average].each do |antenna_name, mi|
				mi_map[tag.position] = mi if antenna_name == antenna
			end
		end
		mi_map
	end






	def create_regression_arrays(antenna_number, mi_map, max_degree)
		antenna = Antenna.new(antenna_number)

		positions = []
		distances_values = []
		angles_values = []
		mi_values = {}
		mi_map.each do |tag_position, mi|
			if mi != 0.0
				positions << tag_position.to_s
				distances_values << tag_position.distance_to_point(antenna.coordinates)
				angles_values << antenna.coordinates.angle_to_point(tag_position)
				(1..max_degree).each do |degree|
					mi_values[degree] ||= []
					mi_values[degree].push(mi ** degree)
				end
			end
		end
		{
				:positions => positions,
				:distances => distances_values,
				:mi => mi_values,
				:angles => angles_values
		}
	end









end
