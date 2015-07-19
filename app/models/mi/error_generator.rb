class MI::ErrorGenerator
	RSS_BIAS = 0.0
	RSS_STDDEV = 3.00
	#RSS_STDDEV = 6.5
	RSS_RR_CORRELATION = 0.65
	#ERROR_COMPONENTS_WEIGHTS = {
	#		general: 0.24,							# general component, depends on near node points
	#		antennas: 0.29,          		# component, depends on near node points, varies for each antenna
	#		reader_powers: 0.18,    		# component, depends on near node points, varies for each reader power
	#		time_random: 0.29						# absolute random component
	#}
	ERROR_COMPONENTS_WEIGHTS = {
			general: 0.7,
			reader_powers: 0.15,
			time_random: 0.15
	}
	#ERROR_COMPONENTS_WEIGHTS = {
	#		general: 1.0,
	#		#reader_powers: 0.0005,
	#		#time_random: 0.0005
	#}

	RSS_ERROR_COMPONENTS_NODE_POINTS = 4 ** 2


	attr_reader :rss_error_cache, :response_probability_number_cache, :errors


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

		sum_of_cubes = ERROR_COMPONENTS_WEIGHTS.values.map{|w| w**3}.sum
		@separate_rss_biases = {}
		@separate_rss_stddevs = {}
		ERROR_COMPONENTS_WEIGHTS.keys.each do |type|
			weight = ERROR_COMPONENTS_WEIGHTS[type].to_f
			@separate_rss_biases[type] = RSS_BIAS.to_f * weight
			#@separate_rss_stddevs[type] = Math.sqrt((RSS_STDDEV.to_f ** 2) / (sum_of_cubes / weight))
			@separate_rss_stddevs[type] = Math.sqrt(RSS_STDDEV.to_f ** 2 / ERROR_COMPONENTS_WEIGHTS.values.map{|w| w**2}.sum)
		end

		puts @separate_rss_biases.to_s
		puts @separate_rss_stddevs.to_s

		heights = (0..3).to_a
		@errors[:general] = calculate_rss_error_components(:general, heights)
		(1..16).each do |antenna_number|
			@errors[:antennas][antenna_number] = calculate_rss_error_components(:antennas, heights)
		end
		(20..30).to_a.push(:sum).each do |reader_power|
			@errors[:reader_powers][reader_power] = calculate_rss_error_components(:reader_powers, heights)
		end
	end





	def get_rss_error(position, reader_power, antenna_number, height_number)
		rss_errors = ERROR_COMPONENTS_WEIGHTS.keys.map do |type|
			type_value = nil
			type_value = antenna_number if type == :antennas
			type_value = reader_power if type == :reader_powers
			get_specific_rss_error(position, type, type_value, height_number)
		end
		#puts @errors[:general].to_yaml
		#puts rss_errors.to_s
		#puts ''
		rss_errors.sum
	end




	#def get_response_probability_number(position, reader_power, antenna_number, height_number)
	#	@response_probability_number_cache[position] ||= {}
		#ERROR_COMPONENTS_WEIGHTS.keys.reject{|type| type == :antennas}.map do |type|
		#	type_value = nil
		#	type_value = reader_power if type == :reader_powers
		#	get_specific_response_probability_number(position, type, type_value, antenna_number, height_number)
		#end.sum
	#end








	#private

	def get_specific_rss_error(position, type_name, type_value, height_number)
		@rss_error_cache[position] ||= {}
		@rss_error_cache[position][height_number] ||= {}
		@rss_error_cache[position][height_number][type_name] ||= {}

		if type_name != :time_random and @rss_error_cache[position][height_number][type_name][type_value].present?
			return @rss_error_cache[position][height_number][type_name][type_value]
		end

		if type_name == :general
			data = @errors[:general][height_number][:rss]
			unweighted_error = Math.bilinear_interpolation(position, data)
		elsif type_name == :position_random or type_name == :time_random or type_name == :time_random2
			unweighted_error = generate_normal(
					@separate_rss_biases[type_name],
					@separate_rss_stddevs[type_name]
			)
		else
			data = @errors[type_name][type_value][height_number][:rss]
			unweighted_error = Math.bilinear_interpolation(position, data)
		end

		error = unweighted_error * ERROR_COMPONENTS_WEIGHTS[type_name]
		return error if type_name == :time_random or type_name == :time_random2
		@rss_error_cache[position][height_number][type_name][type_value] = error
	end

	#def get_specific_response_probability_number(position, type_name, type_value, antenna_number, height_number)
	#	@response_probability_number_cache[position] ||= {}
	#	@response_probability_number_cache[position][height_number] ||= {}
	#	@response_probability_number_cache[position][height_number][antenna_number] ||= {}
	#	@response_probability_number_cache[position][height_number][antenna_number][type_name]||={}
	#
	#
	#	if type_name != :time_random and @response_probability_number_cache[position][height_number][antenna_number][type_name][type_value].present?
	#		return @response_probability_number_cache[position][height_number][antenna_number][type_name][type_value]
	#	end
	#
	#	if type_name == :general
	#		data = @errors[:general][height_number][:numbers][antenna_number]
	#		unweighted_number = Math.bilinear_interpolation(position, data)
	#	elsif type_name == :position_random or type_name == :time_random or type_name == :time_random2
	#		unweighted_number = rand()
	#	else
	#		data = @errors[type_name][type_value][height_number][:numbers][antenna_number]
	#		unweighted_number = Math.bilinear_interpolation(position, data)
	#	end
	#
	#	number = unweighted_number * @weights_without_antennas_component[type_name]
	#	return number if type_name == :time_random or type_name == :time_random2
	#	@response_probability_number_cache[position][height_number][antenna_number][type_name][type_value] = number
	#end






	def calculate_rss_error_components(type, heights)
		bias = @separate_rss_biases[type]
		stddev = @separate_rss_stddevs[type]

		response = {}
		node_points = calculate_node_points
		heights.each do |height|
			response[height] = {}
			response[height][:rss] = calculate_errors(node_points, bias, stddev)
			response[height][:numbers] = calculate_probability_numbers(node_points)
		end

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
	def calculate_errors(node_points, bias, stddev)
		node_points_errors = {}
		node_points.each do |point|
			node_points_errors[point.to_s] = generate_normal(bias, stddev)
		end
		node_points_errors
	end
	def calculate_probability_numbers(node_points)
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