class Algorithm::PointBased::LinearTrilateration < Algorithm::PointBased::Trilateration

  def trainable
    false
  end


  def set_settings(mi_model_type, metric_name, optimization_class, model_type, rr_limit, ellipse_ratio, normalization, penalty_for_antennas_without_answers)
    @mi_model_type = mi_model_type
		@metric_name = metric_name
    @metric_type = :average
    @mi_class = MI::Base.class_by_mi_type(metric_name)
    @optimization = optimization_class.new
    @model_type = model_type
    @rr_limit = rr_limit

    @ellipse_ratio = ellipse_ratio
    @normalization = normalization

    @step = 2.0
		@penalty_for_antennas_without_answers = penalty_for_antennas_without_answers

    self
  end





  def get_decision_function
    decision_functions = {}
    mi = {}
    test_height = 0

    @tags_input[test_height][:test].each do |tag_index, tag|
      mi_hash = tag.answers[@metric_name][@metric_type]
      mi_hash = tag.answers[@metric_name][:average] if mi_hash.empty?

      decision_functions[tag_index] = {}

      mi[tag_index] = {
          :mi => tag.answers[@metric_name][@metric_type],
          :filtered => mi_hash
      }

      polygon = mi_hash.keys.map{|a| @work_zone.antennae[a].coordinates}
      points = Point.points_in_polygon(polygon, @step)
      points.each do |point|
        decision_functions[tag_index][point.x] ||= {}
        decision_functions[tag_index][point.x][point.y] = calc_result_for_point(point, mi_hash)
      end
    end

    {
        :mi => mi,
        :extremum_criterion => @optimization.estimation_extremum_criterion,
        :data => decision_functions
    }
  end










  def model_run_method(height, setup, tag)
    mi_hash = tag.answers[@metric_name][@metric_type]
    mi_hash = mi_hash.dup.keep_if{|k,v| tag.answers[:rr][:average][k] > @rr_limit}
    mi_hash = tag.answers[@metric_name][:average] if mi_hash.empty?
    decision_functions = {}

		#return Point.new(nil,nil) if tag.id.to_s != '0D08'
		#puts '=================================='
		#puts @reader_power.to_s + ' ' + tag.id.to_s + ' ' + mi_hash.to_s

    if mi_hash.length == 1
			#puts 'one'
			current_point = point_for_one_antenna_case(mi_hash)
      #Point.new(nil,nil)
		elsif mi_hash.length == 2
			#puts 'two'
			current_point = point_for_two_antennae_case(mi_hash)
      #Point.new(nil,nil)
		else
			#puts 'three'
			#points = {}
			#current_point = Point.center_of_points(
			#		@work_zone.antennae.select{|i,a| mi_hash.keys.include? i}.values.map{|a| a.coordinates}
			#)
			#previous_point_result = 0.0
			#while true
			#	current_point_result = calc_result_for_point(current_point, mi_hash)
			#
			#	puts current_point.to_s + ' ' + current_point_result.to_s
			#
			#	if (current_point_result - previous_point_result).abs < 1.0
			#		break
			#	end
			#	previous_point_result = current_point_result
			#	current_point = next_point_via_gradient(current_point, current_point_result, mi_hash)
			#	if current_point.nil?
			#		break
			#	end
			#	if points.keys.any? {|p| Point.distance(p, current_point) < 0.0001}
			#		sorted_points = points.sort_by{|p, v| v}
			#		sorted_points = sorted_points.reverse if @optimization.reverse_decision_function?
			#		current_point = sorted_points.first.first
			#		break
			#	end
			#	points[current_point] = current_point_result
			#end



      polygon = mi_hash.keys.map{|a| @work_zone.antennae[a].coordinates}
			#points = Rails.cache.fetch('polygon_points_'+polygon.sort_by{|p| [p.x, p.y]}.to_s + @step.to_s, :expires_in => 5.day) do
			#	Point.points_in_polygon(polygon, @step)
			#end
			points = Rails.cache.fetch('polygon_points2_'+polygon.sort_by{|p| [p.x, p.y]}.to_s + @step.to_s, :expires_in => 5.day) do
				Point.points_in_rectangle(polygon, @step)
			end
      points.each do |point|
        decision_functions[point] = calc_result_for_point(point, mi_hash, tag)
      end

      #puts ''
      #puts polygon.to_s
      #puts Point.points_in_polygon(polygon, @step).to_s
      #puts points.to_s
      #puts decision_functions.to_yaml
      #puts decision_functions.to_yaml
			current_point = decision_functions.sort_by{|point, v| v}.first.first
      #else
      #Point.new(nil,nil)
		end

		#puts current_point.to_s
		#puts ''
		estimate = current_point
		remove_bias(tag, setup, estimate)
  end







  private






  def calc_result_for_point(point, mi_hash, tag = nil)
    #puts mi_hash.to_s
    #mi_hash.each{|k,mi_value| mi_hash[k] = MI::Rss.to_watt(mi_value)}

		#puts ''
		#puts point.to_s
		#puts mi_hash.to_s
		d_max = 100.0

    rr_shift = 0.0000001

    range = @mi_class.range
		if @metric_name == :rss
			if @mi_model_type == :theoretical
				range_hash = MI::Rss.theoretical_range(@reader_power)
				range = [range_hash[:max], range_hash[:min]]
			else
				range = [-55.0, -75.0]
			end
		end
		if @metric_name == :rr
			range = [0.0, 1.0]
		end
    #range = range.map{|dbm| MI::Rss.to_watt(dbm)}

    max_antenna_number = mi_hash.sort_by{|a, mi| mi}.reverse.first.first
    max_antenna = @work_zone.antennae[max_antenna_number]

    distances = {}
    resulted_distances = {}

    mi0 = mi_hash[max_antenna_number]
    (mi_hash.keys - [max_antenna_number]).each do |antenna_number|
      antenna = @work_zone.antennae[antenna_number]

      mi1 = mi_hash[antenna_number]

      d1 = Point.distance(antenna.coordinates, point)
      d0 = Point.distance(max_antenna.coordinates, point)

      angle1 = antenna_point_angle(antenna, point)
      angle0 = antenna_point_angle(max_antenna, point)

      e1 = MI::Base.ellipse(angle1, @ellipse_ratio)
      e0 = MI::Base.ellipse(angle0, @ellipse_ratio)

      distances[antenna_number] = d1

			if @normalization == :local_maximum
        resulted_distances[antenna_number] = d0 * (range[0] - mi1) / (range[0] - mi0) if @metric_name == :rss
        resulted_distances[antenna_number] = d0 * (mi0 + rr_shift) / (mi1 + rr_shift) if @metric_name == :rr
        resulted_distances[antenna_number] *= e1 / e0 if @model_type == :ellipse
      elsif @normalization == :global_maximum
        resulted_distances[antenna_number] = d_max * (range[0] - mi1) / (range[0] - range[1])
        resulted_distances[antenna_number] *= e1 if @model_type == :ellipse
      end
    end



		error_part1 = @optimization.compare_vectors(
        distances,
        resulted_distances,
        {},
        double_sigma_power
    )
		#puts 'd:'+distances.to_s
		#puts resulted_distances.to_s
		#puts 'ERRORPART1: ' + error_part1.to_s

		antennas_without_answers = (@work_zone.antennae.keys - mi_hash.keys)
		error_part2 = error_for_antennas_without_answers(point, antennas_without_answers, tag)
		#puts 'ERRORPART2: ' + error_part2.to_s

		error_part1.send(@optimization.method_for_adding, error_part2)
	end






  def antenna_point_angle(antenna, point)
    ac = antenna.coordinates
    angle = Math.atan2(point.y - ac.y, point.x - ac.x)
    angle = opposite_angle(angle) unless @optimization.reverse_decision_function?
    angle
	end




	def error_for_antennas_without_answers(point, antennas_without_answers, tag = nil)
		if @penalty_for_antennas_without_answers == false
			return @optimization.default_value_for_decision_function
		end
		if @model_type == :ellipse
			zone_size = Zone::POWERS_TO_SIZES[@reader_power].last
		else
			zone_size = Zone::POWERS_TO_SIZES[@reader_power].mean
		end

		distances = []
		resulted_distances = []
		antennas_without_answers.each do |antenna_number|
			antenna = @work_zone.antennae[antenna_number]

			ellipse_coeff = 1.0
			if @model_type == :ellipse
				angle = antenna_point_angle(antenna, point)
				ellipse_coeff = MI::Base.ellipse(angle, @ellipse_ratio)
			end

			distance = Point.distance(antenna.coordinates, point)
			current_zone_size = zone_size * ellipse_coeff

			#if tag != nil and tag.id.to_s == '0D08'
			#	if point.y.to_i == 310
			#		puts antenna.number.to_s
			#		puts (angle.to_f * 180.0 / Math::PI).to_s
			#		puts ellipse_coeff.to_s
			#		puts current_zone_size.to_s
			#		puts distance.to_s
			#		puts ''
			#	end
			#end
			if distance < current_zone_size
				#puts 'found!'
				distances.push(distance)
				resulted_distances.push(current_zone_size)
			end
		end

		@optimization.compare_vectors(
				distances,
				resulted_distances,
				{},
				double_sigma_power
		)
	end




	def point_for_one_antenna_case(mi_hash)
		antenna_number = mi_hash.keys.first
		antenna = @work_zone.antennae[antenna_number]
		coords = antenna.coordinates

		if antenna.near_walls? and @mi_model_type != :theoretical
			mi = mi_hash.values.first.abs

			if @metric_name == :rss
				mi_range = @mi_class.range.map{|v|v.abs}
				difference = mi_range[1] - mi_range[0]
				weights = []
				if mi < mi_range[1]
					weights = [(mi_range[1] - mi).abs / difference, (mi - mi_range[0]).abs / difference]
				end
			else
				weights = [mi.to_f, 1.0 - mi.to_f]
			end

			coords = Point.center_of_points([coords, antenna.nearest_wall_point], weights)
		end

		Point.new(coords.x, coords.y)
	end

	def point_for_two_antennae_case(mi_hash)
		min = @mi_class.range[0].abs

		antennae_coords = @work_zone.
				antennae.
				select{|n,a| mi_hash.keys.include? n}.
				values.
				map{|a| a.coordinates}
		mi_array = mi_hash.values.map(&:abs)

		if @metric_name == :rss
			total = mi_array.sum - 2 * min

			weights = []
			if min < mi_array.min
				weights = [
						(mi_array[1] - min).abs.to_f / total,
						(mi_array[0] - min).abs.to_f / total
				]
			end
		else
			total = mi_array.sum
			weights = [mi_array[0].to_f / total, mi_array[1].to_f / total]
		end

		Point.center_of_points(antennae_coords, weights)
	end

end