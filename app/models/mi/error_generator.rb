class MI::ErrorGenerator
	RSS_BIAS = -0.3
	RSS_STDDEV = 3.5
	RSS_RR_CORRELATION = 0.75
	ERROR_COMPONENTS_WEIGHTS = {
			general: 0.5,
			antennas: 0.2,
			reader_powers: 0.2,
			random: 0.1
	}
	RSS_ERROR_COMPONENTS_NODE_POINTS = 4 ** 2



	def initialize
		@rss_error_cache = {}
		@response_probability_number_cache = {}
		@errors = {
				:general => nil,
				:antennas => {},
				:reader_powers => {}
		}

		sum = ERROR_COMPONENTS_WEIGHTS.reject{|k,v| k == :antennas}.values.sum
		@weights_without_antennas_component = ERROR_COMPONENTS_WEIGHTS.dup.reject{|k,v| k == :antennas}
		@weights_without_antennas_component.each{|k,v|@weights_without_antennas_component[k]=v/sum}


		@separate_rss_biases = {}
		@separate_rss_stddevs = {}
		error_types.each do |type|
			@separate_rss_biases[type] = RSS_BIAS.to_f * ERROR_COMPONENTS_WEIGHTS[type].to_f
			@separate_rss_stddevs[type] = Math.sqrt((RSS_STDDEV.to_f ** 2) * (ERROR_COMPONENTS_WEIGHTS[type].to_f ** 2))
		end


		@errors[:general] = calculate_rss_error_components(:general)
		(1..16).each do |antenna_number|
			@errors[:antennas][antenna_number] = calculate_rss_error_components(:antennas)
		end
		(20..30).to_a.push(:sum).each do |reader_power|
			@errors[:reader_powers][reader_power] = calculate_rss_error_components(:reader_powers)
		end
	end




	def error_types
		[:general, :antennas, :reader_powers, :random]
	end




	def get_rss_error(position, reader_power, antenna_number)
		rss_errors = error_types.map do |type|
			type_value = nil
			type_value = antenna_number if type == :antennas
			type_value = reader_power if type == :reader_powers
			get_specific_rss_error(position, type, type_value)
		end
		rss_errors.sum
	end




	def get_response_probability_number(position, reader_power, antenna_number)
		error_types.reject{|type| type == :antennas}.map do |type|
			type_value = nil
			type_value = reader_power if type == :reader_powers
			get_specific_response_probability_number(position, type, type_value, antenna_number)
		end.sum
	end








	private

	def get_specific_rss_error(position, type_name, type_value)
		@rss_error_cache[position] ||= {}
		@rss_error_cache[position][type_name] ||= {}

		if @rss_error_cache[position][type_name][type_value].present?
			return @rss_error_cache[position][type_name][type_value]
		end

		if type_name == :general
			data = @errors[type_name][:rss]
			unweighted_error = Math.bilinear_interpolation(position, data)
		elsif type_name == :random
			unweighted_error = generate_normal(
					@separate_rss_biases[type_name],
					@separate_rss_stddevs[type_name]
			)
		else
			data = @errors[type_name][type_value][:rss]
			unweighted_error = Math.bilinear_interpolation(position, data)
		end

		@rss_error_cache[position][type_name][type_value] =
				unweighted_error * ERROR_COMPONENTS_WEIGHTS[type_name]
	end

	def get_specific_response_probability_number(position, type_name, type_value, antenna_number)
		@response_probability_number_cache[position] ||= {}
		@response_probability_number_cache[position][type_name] ||= {}

		if @response_probability_number_cache[position][type_name][type_value].present?
			return @response_probability_number_cache[position][type_name][type_value]
		end

		if type_name == :general
			data = @errors[type_name][:responses][antenna_number]
			unweighted_number = Math.bilinear_interpolation(position, data)
		elsif type_name == :random
			unweighted_number = rand()
		else
			data = @errors[type_name][type_value][:responses][antenna_number]
			unweighted_number = Math.bilinear_interpolation(position, data)
		end

		@response_probability_number_cache[position][type_name][type_value] =
				unweighted_number * @weights_without_antennas_component[type_name]
	end






	def calculate_rss_error_components(type)
		puts @separate_rss_biases.to_s
		puts type.to_s
		bias = @separate_rss_biases[type]
		stddev = @separate_rss_stddevs[type]

		response = {}
		node_points = calculate_node_points
		response[:rss] = calculate_node_points_errors(node_points, bias, stddev)
		response[:responses] = calculate_node_points_responses(node_points)
		response
	end

	def calculate_node_points
		points = []
		shift = 20
		node_points_in_row = Math.sqrt(RSS_ERROR_COMPONENTS_NODE_POINTS)
		step = (WorkZone::WIDTH - 2 * shift) / node_points_in_row
		(0...node_points_in_row).each do |x_step|
			x = step + x_step * step
			(0...node_points_in_row).each do |y_step|
				y = step + y_step * step
				points.push(Point.new(x, y))
			end
		end
		points
	end
	def calculate_node_points_errors(node_points, bias, stddev)
		node_points_errors = {}
		node_points.each do |point|
			node_points_errors[point.to_s] = generate_normal(bias, stddev)
		end
		node_points_errors
	end
	def calculate_node_points_responses(node_points)
		node_points_responses = {}
		(1..16).each do |antenna_number|
			node_points_responses[antenna_number] ||= {}
			node_points.each do |point|
				node_points_responses[antenna_number][point.to_s] = rand()
			end
		end
		node_points_responses
	end






	def generate_normal(bias, stddev)
		return bias if stddev.nil? or stddev.zero?
		Rubystats::NormalDistribution.new(bias.to_f, stddev.to_f).rng.to_f
	end

end