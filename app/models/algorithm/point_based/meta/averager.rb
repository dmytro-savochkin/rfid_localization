class Algorithm::PointBased::Meta::Averager < Algorithm::PointBased

  attr_reader :algorithms, :group

  def initialize(algorithms, manager_id, group, tags_input)
    @algorithms = algorithms
    @tags_input = tags_input
    @manager_id = manager_id
    @group = group
		@rinruby = RinRuby.new(echo = false)
  end


  def set_settings(apply_stddev_weighting, correlation_weighting, special_case_one_antenna, special_case_small_variances, apply_centroid_weighting, variance_decrease_coefficient, averaging_type, tags_count_for_correlation, weights = [])
    @apply_stddev_weighting = apply_stddev_weighting
    @correlation_weighting = correlation_weighting
    @special_case_one_antenna = special_case_one_antenna
    @special_case_small_variances = special_case_small_variances
    @variance_decrease_coefficient = variance_decrease_coefficient
    @apply_centroid_weighting = apply_centroid_weighting

    @averaging_type = averaging_type
    @tags_count_for_correlation = tags_count_for_correlation
    @weights = weights
    self
  end









  private

  def train_model(train_data, heights, model_id)
  end

  def set_up_model(model, train_data, setup_data, height_index)
    correlation_weights = []
    correlation_weights_x = []
    correlation_weights_y = []

    # может быть в будущем вернуться к постоянному добавлению новых оценок с пересчетом к-тов

    correlations_methods = {
        :rv => :rv_coefficient,
        :brownian => :brownian_correlation
    }




    if @correlation_weighting
      sigmas = {}
      sigmas_x = {}
      sigmas_y = {}
			@algorithms.each do |k, algorithm|
				if @apply_stddev_weighting
					sigmas[k] = algorithm.setup[height_index][:means][:all][:total]
					#sigmas[k] = Math.sqrt(
					#		algorithm.setup[height_index][:stddevs][:all][:x] *
					#		algorithm.setup[height_index][:stddevs][:all][:y]
					#)
					#sigmas[k] = (
					#		algorithm.setup[height_index][:stddevs][:all][:x] +
					#		algorithm.setup[height_index][:stddevs][:all][:y]
					#)/2
					sigmas_x[k] = algorithm.setup[height_index][:stddevs][:all][:x]
					sigmas_y[k] = algorithm.setup[height_index][:stddevs][:all][:y]
				else
					sigmas[k] = 1.0
					sigmas_x[k] = 1.0
					sigmas_y[k] = 1.0
				end
			end
			puts 'sigmas:'
			puts sigmas.to_s
			puts sigmas_x.to_s
			puts sigmas_y.to_s



			cov = Matrix.build(@algorithms.length, @algorithms.length) {|row, col| nil }
			cov_x = Matrix.build(@algorithms.length, @algorithms.length) {|row, col| nil }
			cov_y = Matrix.build(@algorithms.length, @algorithms.length) {|row, col| nil }
			unity = Matrix.build(@algorithms.length, 1) {|row, col| 1.0 }
			#sorted_antennas[0..2].each_with_index do |antenna, i|
			#	distance = distances[antenna.number]
			#	h_matrix[i, 0] = (antenna.coordinates.x - point.x) / distance
			#	h_matrix[i, 1] = (antenna.coordinates.y - point.y) / distance
			#	#h_matrix[i, 2] = -1.0
			#end
			#h_matrix = h_matrix.map{|e| if e.nan? then 1.0 else e end}
			##q_matrix = (h_matrix.transpose * w_matrix * h_matrix).inverse
			##gdop[x][y] = Math.sqrt(q_matrix[0,0] + q_matrix[1,1])
			##puts gdop[x][y].to_s
			#q_matrix = (h_matrix.transpose * h_matrix).inverse



			correlation = {}
      correlation_x = {}
      correlation_y = {}

      @algorithms.each_with_index do |(index1, algorithm1), i1|
        #estimates1 = algorithm1.setup[height_index][:estimates]
        #estimates1 = Hash[algorithm1.setup[height_index][:estimates].sort_by{|k,v|k}[0...@tags_count_for_correlation]]

        #if @tags_count_for_correlation == nil
          estimates1 = Hash[algorithm1.setup[height_index][:estimates].sort_by{|k,v|k}]
        	errors1 = Hash[algorithm1.setup[height_index][:errors][:total].sort_by{|k,v|k}]
        	errors1x = Hash[algorithm1.setup[height_index][:errors][:x].sort_by{|k,v|k}]
        	errors1y = Hash[algorithm1.setup[height_index][:errors][:y].sort_by{|k,v|k}]
				#else
        #  estimates1 = Hash[algorithm1.setup[height_index][:estimates].sort_by{|k,v|k}[0...@tags_count_for_correlation]]
        #end

        #puts estimates1.values.to_s


        correlation[index1] ||= {}
        #correlation_x[index1] ||= {}
        #correlation_y[index1] ||= {}

				@algorithms.each_with_index do |(index2, algorithm2), i2|
						#puts algorithm2.setup[height_index].to_s
          #if @tags_count_for_correlation == nil
            estimates2 = Hash[algorithm2.setup[height_index][:estimates].sort_by{|k,v|k}]
						errors2 = Hash[algorithm2.setup[height_index][:errors][:total].sort_by{|k,v|k}]
						errors2x = Hash[algorithm2.setup[height_index][:errors][:x].sort_by{|k,v|k}]
						errors2y = Hash[algorithm2.setup[height_index][:errors][:y].sort_by{|k,v|k}]

          #else
          #  estimates2 = Hash[algorithm2.setup[height_index][:estimates].sort_by{|k,v|k}[0...@tags_count_for_correlation]]
          #end


          #if @tags_count_for_correlation == nil
          #  if estimates1.keys.to_s != estimates2.keys.to_s
          #    puts algorithm1.to_s + ' ' + algorithm2.to_s
          #    puts estimates1.keys.to_s
          #    puts estimates2.keys.to_s
          #    puts ''
          #  end
          #end





          if estimates1.length != estimates2.length
            keys_to_keep = [estimates1.keys, estimates2.keys].sort_by(&:length)[0]
            estimates1 = estimates1.keep_if{|k,v| keys_to_keep.include? k}
            estimates2 = estimates2.keep_if{|k,v| keys_to_keep.include? k}
					end
					if errors1.length != estimates2.length
						keys_to_keep = [errors1.keys, errors2.keys].sort_by(&:length)[0]
						errors1 = errors1.keep_if{|k,v| keys_to_keep.include? k}
						errors1x = errors1x.keep_if{|k,v| keys_to_keep.include? k}
						errors1y = errors1y.keep_if{|k,v| keys_to_keep.include? k}
						errors2 = errors2.keep_if{|k,v| keys_to_keep.include? k}
						errors2x = errors2x.keep_if{|k,v| keys_to_keep.include? k}
						errors2y = errors2y.keep_if{|k,v| keys_to_keep.include? k}
					end

          #puts 'e2 ' + estimates1.values.map{|p| [p.x, p.y]}.to_s

          #puts estimates1.values.map{|p| [p.x, p.y]}.to_s
          #puts estimates2.values.map{|p| [p.x, p.y]}.to_s
          #puts ''

					cov_x[i1, i2] = Math.correlation(errors1x.values, errors2x.values)
					cov_y[i1, i2] = Math.correlation(errors1y.values, errors2y.values)

					if @correlation_weighting == :error
						correlation[index1][index2] = Math.correlation(errors1.values, errors2.values)
						cov[i1, i2] 				= Math.correlation(errors1.values, errors2.values)
					elsif @correlation_weighting == :error_x_y
						val = Math.correlation(errors1x.values, errors2x.values)/2 +
								Math.correlation(errors1y.values, errors2y.values)/2
						correlation[index1][index2] = val
						cov[i1, i2] = val
					elsif @correlation_weighting == :different
						correlation[index1][index2] = 1.0
						cov[i1, i2] = 1.0
					else
						points1 = estimates1.values.map{|p| [p.x, p.y]}
						#points1_x = estimates1.values.map{|p| p.x}
						#points1_y = estimates1.values.map{|p| p.y}
						points2 = estimates2.values.map{|p| [p.x, p.y]}
						#points2_x = estimates2.values.map{|p| p.x}
						#points2_y = estimates2.values.map{|p| p.y}

						correlation[index1][index2] = Math.send(
								correlations_methods[@correlation_weighting],
								points1,
								points2
						)
						cov[i1, i2] = correlation[index1][index2]
					end

					correlation[index1][index2] *= sigmas[index1]*sigmas[index2]
					cov[i1, i2] = cov[i1, i2] * sigmas[index1] * sigmas[index2]
					cov_x[i1, i2] = cov_x[i1, i2] * sigmas_x[index1] * sigmas_x[index2]
					cov_y[i1, i2] = cov_y[i1, i2] * sigmas_y[index1] * sigmas_y[index2]


          #correlation_x[index1][index2] = Math.correlation(points1_x, points2_x)
          #correlation_y[index1][index2] = Math.correlation(points1_y, points2_y)

          #puts correlation[index1][index2].to_s
          #puts Math.rv_coefficient(
          #    estimates1.values.map{|p| [p.x, p.y]},
          #    estimates2.values.map{|p| [p.x, p.y]}
          #)
        end

        #puts algorithm1.to_s
        #puts correlation[index1].to_s
        #puts ''

        correlation_weights.push( correlation[index1].values.map{|corr| 1.0 / corr}.sum )
        #correlation_weights_x.push(correlation_x[index1].values.map{|corr| 1.0 / corr}.sum)
        #correlation_weights_y.push(correlation_y[index1].values.map{|corr| 1.0 / corr}.sum)
      end

      puts @correlation_weighting.to_s
      puts correlation.to_yaml
      puts correlation_weights.to_yaml
      #puts correlation_weights_x.to_yaml
      #puts correlation_weights_y.to_yaml
      puts ''

			puts 'and new!'

			if @correlation_weighting == :different
				weights_x = cov_x.inverse * unity / (unity.transpose * cov_x.inverse * unity)
				weights_y = cov_y.inverse * unity / (unity.transpose * cov_y.inverse * unity)
				correlation_weights.each_with_index do |w, i|
					correlation_weights[i] = 1.0
					correlation_weights_x[i] = weights_x[i, 0].to_s.to_f
					correlation_weights_y[i] = weights_y[i, 0].to_s.to_f
				end
			else
				weights = cov.inverse * unity / (unity.transpose * cov.inverse * unity)
				correlation_weights.each_with_index do |w, i|
					correlation_weights[i] = weights[i, 0].to_s.to_f
					correlation_weights_x[i] = 1.0
					correlation_weights_y[i] = 1.0
				end
			end

			puts sigmas.to_s
			puts correlation_weights.to_s
			puts correlation_weights_x.to_s
			puts correlation_weights_y.to_s
			puts ''

    end

    [correlation_weights, correlation_weights_x, correlation_weights_y]
  end

  #def update_correlation_weights(height_index, new_estimates)
  #  correlation_weights = []
  #
  #  if @correlation_weighting
  #    correlation = {}
  #
  #    @algorithm_estimates ||= {}
  #
  #    if @algorithm_estimates[height_index].nil?
  #      @algorithm_estimates[height_index] = {}
  #      @algorithms.values.each_with_index do |algorithm, index|
  #        @algorithm_estimates[height_index][index] =
  #            algorithm.setup[height_index][:estimates].values
  #      end
  #    end
  #
  #    new_estimates.each_with_index do |new_estimate, index|
  #      @algorithm_estimates[height_index][index].push new_estimate
  #    end
  #
  #    #puts @algorithm_estimates[height_index].to_s
  #
  #    @algorithm_estimates[height_index].values.each_with_index do |estimates1, index1|
  #      correlation[index1] ||= {}
  #      @algorithm_estimates[height_index].values.each_with_index do |estimates2, index2|
  #        correlation[index1][index2] =
  #            #Math.rv_coefficient(
  #            Math.brownian_correlation(
  #                estimates1.map{|p| [p.x, p.y]},
  #                estimates2.map{|p| [p.x, p.y]}
  #            )
  #      end
  #      correlation_weights.push(correlation[index1].values.map{|corr| 1.0 - corr}.sum)
  #    end
  #  end
  #
  #  correlation_weights
  #end




  def calc_tags_estimates(model, setup, tags_input, height_index)
    tags_estimates = {}

    tags_input.each do |tag_index, tag|
      estimate = make_estimate(setup, tag, height_index)
      tag_output = TagOutput.new(tag, estimate)
      tags_estimates[tag_index] = tag_output
    end

    tags_estimates
  end







  def make_estimate(setup, tag, height_index)
    tag_index = tag.id.to_s

    correlation_weights, correlation_weights_x, correlation_weights_y = setup[height_index]

    #correlation_weights = update_correlation_weights(
    #    height_index,
    #    #@algorithms.values.map{|a| a.map[height_index][tag_index][:estimate]}
    #    []
    #)

    all_points = []
    hash = {}

		puts 'TAG:'+tag_index.to_s

    stddev_weights = generate_stddev_weights(tag, height_index)

    @algorithms.each_with_index do |(algorithm_name, algorithm), i|
      if algorithm.map[height_index][tag_index].present?
        answers_count = algorithm.map[height_index][tag_index][:answers_count]

        point = algorithm.map[height_index][tag_index][:estimate].to_s
        hash[point] ||= {:point => 0, :weight => 0.0}
        hash[point][:point] += 1

        all_points.push algorithm.map[height_index][tag_index][:estimate]

        if @weights.present?
          if @weights[i][answers_count.to_s].present?
            weight = @weights[i][answers_count.to_s]
          elsif @weights[i][:other].present?
            weight = @weights[i][:other]
          else
            weight = 0.0
          end
          hash[point][:weight] += weight
        end
      end
    end

    #return nil if points_hash.empty?
    #puts train_height.to_s + ' - ' + test_height.to_s + ' ' + tag.id.to_s + ': ' + weights.to_s

    #puts all_points.to_s


    points = all_points
    points = hash.keys.map{|point_string| Point.from_s(point_string)} if @averaging_type == :equal

    centroid_weights = generate_centroid_weights(points)

    weights = []
    weights = hash.values.map{|h| h[:weight]} if @weights.present?


    #puts tag_index.to_s

    #puts 'TTT' if tag_answers_counts[0] == 1
    ##if @apply_stddev_weighting
    #  #puts stddev_weights.to_s
    #  #puts tag_answers_counts.to_s
    #  #puts variances.to_s
    #  #puts @algorithms.values.
    #  #    map.with_index{|a, i| a.setup[height_index][:lengths][tag_answers_counts[i]]}.to_s
    ##end
    ##puts small_variance_points.to_s

    #puts points.to_s
    #puts stddev_weights.to_s
    #puts correlation_weights.to_s

    result_weights = {x: [], y: [], total: []}
		[:x, :y, :total].each do |dimension|
			points.each_with_index do |point, i|
				result_weights[dimension][i] = 1.0

				result_weights[dimension][i] *= stddev_weights[i] if stddev_weights[i].present?
				if correlation_weights[i].present?
					result_weights[dimension][i] *= correlation_weights[i] if dimension == :total
					result_weights[dimension][i] *= correlation_weights_x[i] if dimension == :x
					result_weights[dimension][i] *= correlation_weights_y[i] if dimension == :y
				end
				result_weights[dimension][i] *= weights[i] if weights[i].present?
				result_weights[dimension][i] *= centroid_weights[i] if centroid_weights[i].present?
			end

			result_weights[dimension] = [] if result_weights[dimension].all?{|w|w.zero?}
		end

		puts weights.to_s
		puts centroid_weights.to_s
		puts correlation_weights.to_s

    #puts 'res weights:'+result_weights.to_s
    #puts ''
		puts stddev_weights.to_s

		if @correlation_weighting == :different
			x = points.each_with_index.map{|p, i| p.x * result_weights[:x][i]}.sum
			y = points.each_with_index.map{|p, i| p.y * result_weights[:y][i]}.sum
			x = 0.0 if x < 0.0
			x = WorkZone::WIDTH if x > WorkZone::WIDTH
			y = 0.0 if y < 0.0
			y = WorkZone::HEIGHT if y > WorkZone::HEIGHT
			Point.new(x, y)
		else
			result = Point.center_of_points(points, result_weights[:total])


			[:x, :y].each do |dim|
				print '('
				el = []
				points.each_with_index do |point, i|
					w = stddev_weights[i]
					el << (w.to_s + '*' + point.send(dim).to_s)
				end
				print el.join(' + ')
				print ') * (1.0/ '
				print stddev_weights.sum.to_s
				puts ')'
			end



			puts points.to_s
			puts result.to_s
			puts ''
			result
		end
  end





  def generate_centroid_weights(points)
    centroid_weights = []
    if @apply_centroid_weighting
      centroid = Point.center_of_points(points)
      distances_to_centroid = points.map{|point| Point.distance(point, centroid)}
      min_distance = 10.0
      max_distance = 100.0
      distances_to_centroid.each do |distance_to_centroid|
        if distance_to_centroid < min_distance
          centroid_weights.push 1.0
        elsif distance_to_centroid > max_distance
          centroid_weights.push 0.00
        else
          centroid_weights.push(
							(max_distance - distance_to_centroid) / (max_distance-min_distance)
					)
        end
      end
    end
    centroid_weights
  end

  def generate_stddev_weights(tag, height_index)
		tag_index = tag.id.to_s

    # apply means unbiasing - отдельно
		# про возможность дообучения после калибровки сказать просто что так можно
    # w3 - small variance (1 если алгоритм во время калибровки имел маленькую дисперсию, 0 - иначе)
		# при этом включается только если число таких алгоритмов (источников оценок) больше лимита (4)
		# w4 - apply stddev weighting - как в тезисах mikon (по числу антенн + без этого) (если без корреляции)
		# w5 - корреляция

		algorithms_with_small_variance = []
    variance_limit = 15.0
    small_variances_limit = 4


    stddev_weights = []

    tag_answers_counts = []
    @algorithms.values.each_with_index do |algorithm, i|
      if algorithm.map[height_index][tag_index].present?
        tag_answers_counts.push(
            algorithm.tags_input[height_index][:test][tag_index].answers_count
        )
      end
    end



    if @apply_stddev_weighting
			if @apply_stddev_weighting == :bordered and tag.in_center?
				nil
			else
				if @apply_stddev_weighting == :all
					stddevs_objects = @algorithms.values.
							map.with_index{|a, i| a.setup[height_index][:stddevs][:all]}
					means_objects = @algorithms.values.
							map.with_index{|a, i| a.setup[height_index][:means][:all]}
				elsif @apply_stddev_weighting == :four_or_more
					stddevs_objects = @algorithms.values.map.with_index do |a, i|
						count = (tag_answers_counts[i] >= 3 ? :four_or_more : tag_answers_counts[i])
						a.setup[height_index][:stddevs][count]
					end
					means_objects = @algorithms.values.map.with_index do |a, i|
						count = (tag_answers_counts[i] >= 3 ? :four_or_more : tag_answers_counts[i])
						a.setup[height_index][:means][count]
					end
				else
					stddevs_objects = @algorithms.values.
							map.with_index{|a, i| a.setup[height_index][:stddevs][tag_answers_counts[i]]}
					means_objects = @algorithms.values.
							map.with_index{|a, i| a.setup[height_index][:means][tag_answers_counts[i]]}
				end

				means = means_objects.map do |means_object|
					if means_object.nil?
						Float::NAN
					else
						means_object[:total]
					end
				end
				stddevs = stddevs_objects.map do |stddev_object|
					if stddev_object.nil?
						Float::NAN
					else
						#stddev_object[:total]
						Math.sqrt(stddev_object[:x] * stddev_object[:y])
					end
				end
				variances = stddevs.map{|stddev| stddev ** 2}
				#sum_of_inverted_means = means.map{|mean| 1.0/mean}.reject{|v|v.nan?}.sum

				@algorithms.values.each_with_index do |algorithm, i|
					if algorithm.map[height_index][tag_index].present?
						if @apply_stddev_weighting == :all
							tags_count_with_that_answers_count = algorithm.
									setup[height_index][:lengths][:all].to_i
							#elsif @apply_stddev_weighting == :four_or_more
							#	count = (tag_answers_counts[i].to_i >= 3 ? tag_answers_counts[i] : :four_or_more)
							#	tags_count_with_that_answers_count = algorithm.
							#			setup[height_index][:lengths][count].to_i
						else
							tags_count_with_that_answers_count = algorithm.
									setup[height_index][:lengths][tag_answers_counts[i]].to_i
						end

						if tags_count_with_that_answers_count > 2

							if algorithm.trainable and algorithm.model_must_be_retrained
								variance = variances[i] * @variance_decrease_coefficient.to_f
								stddev = stddevs[i] * @variance_decrease_coefficient.to_f
								mean = means[i] * @variance_decrease_coefficient.to_f
							else
								variance = variances[i]
								stddev = stddevs[i]
								mean = means[i]
							end

							#stddev_weight = 1.0 / (mean + variance)
							if @apply_stddev_weighting == :stddev or
									@apply_stddev_weighting == :four_or_more or
									@apply_stddev_weighting == :bordered
								stddev_weight = 1.0 / variance
							elsif @apply_stddev_weighting == :mean
								stddev_weight = 1.0 / (mean * Math::sqrt(2.0/Math::PI)) ** 2
							else
								stddev_weight = 1.0
							end

							if @special_case_small_variances
								if stddevs[i] <= variance_limit
									algorithms_with_small_variance.push i
								end
							end

						else
							stddev_weight = Float::NAN
						end

						stddev_weights.push(stddev_weight)
					end
				end


				if stddev_weights.all?{|w| w.nan?}
					stddev_weights = []
				else
					stddev_weights_mean = stddev_weights.reject{|w| w.nan?}.mean
					stddev_weights.each_with_index do |stddev_weight, i|
						stddev_weights[i] = stddev_weights_mean if stddev_weights[i].nan?
					end
				end


				if @special_case_small_variances
					if algorithms_with_small_variance.length >= small_variances_limit
						#puts 'small_variances: ' + small_variance_points.to_s
						stddev_weights.each_with_index do |stddev_weight, i|
							stddev_weights[i] = 0.0 unless algorithms_with_small_variance.include? i
						end
					end
				end
			end
    end

		puts tag_answers_counts.to_s

    if @special_case_one_antenna
			if tag_answers_counts[0] == 1
				@algorithms.values.each_with_index do |algorithm, i|
					if algorithm.trainable
            stddev_weights[i] = 0.0
          else
            stddev_weights[i] = 1.0 if stddev_weights[i].nil?
          end
        end
      end
    end

    #puts stddev_weights.to_s
		#puts ''

    stddev_weights
  end






  #def create_stddev_weight(algorithm, sum_of_inverted_variances, variance, answers_count, height_index)
  #  #max_stddev = 50.0
  #
  #  tags_with_that_answers_count = algorithm.setup[height_index][:lengths][answers_count].to_i
  #  if sum_of_inverted_variances.present? and tags_with_that_answers_count > 5
  #    stddev_weight = (1.0 / variance) / sum_of_inverted_variances
  #
  #    #stddev_weight =
  #    #    [(max_stddev - stddevs_for_that_answers_count[:total]), 0.0].max / max_stddev
  #  else
  #    stddev_weight = 1.0
  #  end
  #
  #  stddev_weight
  #end

end