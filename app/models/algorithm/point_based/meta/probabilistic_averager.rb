class Algorithm::PointBased::Meta::ProbabilisticAverager < Algorithm::PointBased::Meta::Averager

  def set_settings(apply_stddev_weighting, apply_correlation_weighting, special_case_one_antenna, special_case_small_variances, apply_centroid_weighting, variance_decrease_coefficient, averaging_type, probabilities, mode, weights = [])
    @apply_stddev_weighting = apply_stddev_weighting
    @apply_correlation_weighting = apply_correlation_weighting
    @special_case_one_antenna = special_case_one_antenna
    @special_case_small_variances = special_case_small_variances
    @apply_centroid_weighting = apply_centroid_weighting

    @averaging_type = averaging_type
    @probabilities = probabilities
    @weights = weights
    #@calculated_weights = {}
    @zonal_weights_use_mode = mode
    self
  end






  def probabilities_with_zones_keys
    hash = {}

    @probabilities.each do |height_index, tags_data|
      hash[height_index] ||= {}
      tags_data.each do |tag_index, zones_data|
        hash[height_index][tag_index] ||= {}
        zones_data.each do |zone_center, probability|
          hash[height_index][tag_index][Zone.number_from_point(zone_center)] =
              probability
        end
      end
    end

    hash
  end





  private


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





    all_points = []
    hash = {}

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

    points = all_points
    points = hash.keys.map{|point_string| Point.from_s(point_string)} if @averaging_type == :equal







    zone_weights = []
    stddev_weights = generate_stddev_weights(tag_index, height_index)
    correlation_weights = setup[height_index]
    centroid_weights = generate_centroid_weights(points)

    centroid_weights = [] if centroid_weights.any?{|w| w.nan?}
    centroid_weights = [] if centroid_weights.all?{|w| w.zero?}

    #correlation_weights = update_correlation_weights(
    #    height_index,
    #    #@algorithms.values.map{|a| a.map[height_index][tag_index][:estimate]}
    #    []
    #)






    if @probabilities[height_index].keys.include? tag_index
      probabilities = {}

      @probabilities[height_index][tag_index].each do |zone_center, probability|
        if probability > 0.1
          probabilities[zone_center.to_s] = probability
        else
          probabilities[zone_center.to_s] = (1.0 / Math.log(probability, 1.25)).abs
        end
        probabilities[zone_center.to_s] = probability
      end

      if centroid_weights.present?
        centroid = Point.center_of_points(points, centroid_weights)
      else
        centroid = Point.center_of_points(points, [])
      end
      #puts points.to_s
      #puts centroid.to_s
      #puts centroid_weights.to_s

      if @zonal_weights_use_mode == :always or centroid.near_zone_border? == false
        if probabilities.present?

          points.each_with_index do |point|
            point_zone_center = point.zone.coordinates
            probability_of_being_in_point_zone = probabilities[point_zone_center.to_s]

            #if @zonal_weights_use_mode == '1'
            #
            #  zone_weights.push(probability_of_being_in_point_zone)
            #
            #elsif @zonal_weights_use_mode == '2'

            if point_zone_center.to_s == point.to_s
              zone_weights.push(probability_of_being_in_point_zone)
            else
              zones_centers = probabilities.keys.map{|point_as_s| Point.from_s(point_as_s) }
              nearest_zones_centers = point.select_nearest_points(zones_centers)
              nearest_zones_centers_coeffs = point.approximation_proximity_coeffs(nearest_zones_centers)

              p_weight = nearest_zones_centers.map.with_index do |nearest_zone_center, i|
                nearest_zones_centers_coeffs[i] * probabilities[nearest_zone_center.to_s]
              end.sum

              #puts 'tagtag ' + tag.id.to_s
              #puts point.to_s
              #puts nearest_zones_centers.to_s
              #puts nearest_zones_centers_coeffs.to_s
              #puts p_weight.to_s
              #puts ''
              #puts ''

              zone_weights.push p_weight
            end

            #elsif @zonal_weights_use_mode == '3'
            #
            #  most_probable_zone_center = probabilities.sort_by{|k,v|v}.last[0]
            #  most_probable_zone_number = Zone.number_from_point(Point.from_s(most_probable_zone_center))
            #
            #  puts point.to_s
            #if point.in_zone?(most_probable_zone_number)
            #  puts '1'
            #  puts probability_of_being_in_point_zone.to_s
            #zone_weights.push probability_of_being_in_point_zone
            #else
            #puts '2'
            #max_distance = 100.0
            #distance_to_zone = point.shortest_distance_to_zone_border(most_probable_zone_number)
            #
            #puts distance_to_zone.to_s
            #
            #puts tag_index.to_s
            #puts most_probable_zone_number.to_s
            #puts distance_to_zone.to_s
            #puts probabilities[most_probable_zone_center].to_s
            #puts [(max_distance - distance_to_zone) / max_distance, 0.0].max.to_s
            #
            #zone_weights.push( probabilities[most_probable_zone_center] *
            #    [(max_distance - distance_to_zone) / max_distance, 0.01].max )
            #
            #puts probabilities[most_probable_zone_center].to_s
            #puts ((max_distance - distance_to_zone) / max_distance).to_s
            #end

            #end
          end

          #points.each_with_index do |point|
          #  zones_centers = probabilities.keys
          #  nearest_zones_centers = point.select_nearest_points(zones_centers)
          #  nearest_zones_centers_coeffs = point.approximation_proximity_coeffs(nearest_zones_centers)
          #  point_probability = probabilities.
          #      select{|zone_center, p| nearest_zones_centers.include? zone_center}.
          #      values.
          #      map.with_index{|probability, i| probability * nearest_zones_centers_coeffs[i]}.
          #      sum
          #  p_weights.push point_probability
          #end

          #puts p_weights.to_yaml

          p_weights_sum = zone_weights.sum
          zone_weights = zone_weights.map{|p_weight| p_weight / p_weights_sum} if p_weights_sum != 0.0
        end

        #puts ''
        #puts 'tag. ' + tag.id.to_s
        #puts probabilities.to_s
        #puts points.to_s
        #puts p_weights.to_s
        #puts weights.to_s

        zone_weights = [] if zone_weights.any?{|w| w.nan?}
        zone_weights = [] if zone_weights.all?{|w| w.zero?}
      end
    end









    result_weights = []
    points.each_with_index do |point, i|
      result_weights[i] = 1.0
      result_weights[i] *= stddev_weights[i] if stddev_weights[i].present?
      result_weights[i] *= correlation_weights[i] if correlation_weights[i].present?
      result_weights[i] *= zone_weights[i] if zone_weights[i].present?
      result_weights[i] *= centroid_weights[i] if centroid_weights[i].present?
    end

    result_weights = [] if result_weights.all?{|w|w.zero?}

    Point.center_of_points(points, result_weights)
  end
end