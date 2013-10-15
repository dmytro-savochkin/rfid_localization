class Algorithm::PointBased::Meta::ProbabilisticAverager < Algorithm::PointBased::Meta::Averager


  def set_settings(averaging_type, probabilities, mode, weights = [])
    @averaging_type = averaging_type
    @probabilities = probabilities
    @weights = weights
    @mode = mode
    self
  end


  private




  def calc_tags_estimates(algorithms, tags_input, height_index)
    tags_estimates = {}

    tags_input.each do |tag_index, tag|
      estimate = make_estimate(tag, height_index)
      tag_output = TagOutput.new(tag, estimate)
      tags_estimates[tag_index] = tag_output
    end

    tags_estimates
  end





  def make_estimate(tag, height_index)
    tag_index = tag.id.to_s

    #puts @probabilities.to_yaml
    #puts train_height.to_s + ' xxx ' + test_height.to_s + ' xxx ' + tag_index.to_s


    probabilities = {}
    @probabilities[height_index][tag_index].each do |zone_center, probability|
      probabilities[zone_center.to_s] = probability
    end



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

    #return nil if points_hash.empty?
    #puts train_height.to_s + ' - ' + test_height.to_s + ' ' + tag.id.to_s + ': ' + weights.to_s



    points = all_points
    points = hash.keys.map{|point_string| Point.from_s(point_string)} if @averaging_type == :equal


    p_weights = []
    if probabilities.present?

      points.each_with_index do |point|
        point_zone_center = point.zone.coordinates
        probability_of_being_in_point_zone = probabilities[point_zone_center.to_s]

        if @mode == '1'

          p_weights.push(probability_of_being_in_point_zone)

        elsif @mode == '2'

          if point_zone_center.to_s == point.to_s
            p_weights.push(probability_of_being_in_point_zone)
          else
            zones_centers = probabilities.keys.map{|point_as_s| Point.from_s(point_as_s) }
            nearest_zones_centers = point.select_nearest_points(zones_centers)
            nearest_zones_centers_coeffs = point.approximation_proximity_coeffs(nearest_zones_centers)

            p_weight = nearest_zones_centers.map.with_index do |nearest_zone_center, i|
              nearest_zones_centers_coeffs[i] * probabilities[nearest_zone_center.to_s]
            end.sum

            #puts tag.id.to_s
            #puts point.to_s
            #puts nearest_zones_centers.to_s
            #puts nearest_zones_centers_coeffs.to_s
            #puts p_weight.to_s
            #puts ''
            #puts ''

            p_weights.push p_weight
          end

        elsif @mode == '3'

          most_probable_zone_center = probabilities.sort_by{|k,v|v}.last[0]
          most_probable_zone_number = Zone.number_from_point(Point.from_s(most_probable_zone_center))

          puts point.to_s
          if point.in_zone?(most_probable_zone_number)
            puts '1'
            puts probability_of_being_in_point_zone.to_s
            p_weights.push probability_of_being_in_point_zone
          else
            puts '2'
            max_distance = 100.0
            distance_to_zone = point.shortest_distance_to_zone_border(most_probable_zone_number)

            puts distance_to_zone.to_s

            #puts tag_index.to_s
            #puts most_probable_zone_number.to_s
            #puts distance_to_zone.to_s
            #puts probabilities[most_probable_zone_center].to_s
            #puts [(max_distance - distance_to_zone) / max_distance, 0.0].max.to_s

            p_weights.push( probabilities[most_probable_zone_center] *
                [(max_distance - distance_to_zone) / max_distance, 0.01].max )

            puts probabilities[most_probable_zone_center].to_s
            puts ((max_distance - distance_to_zone) / max_distance).to_s
          end

        end
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

      p_weights_sum = p_weights.sum
      p_weights = p_weights.map{|p_weight| p_weight / p_weights_sum} if p_weights_sum != 0.0
    end



    #puts ''
    puts tag.id.to_s
    puts probabilities.to_s
    puts points.to_s
    puts p_weights.to_s
    puts ''
    puts ''

    p_weights = [] if p_weights.any?{|w| w.nan?}

    weights = []
    weights = hash.values.map{|h| h[:weight]} if @weights.present?

    Point.center_of_points(points, p_weights)
  end
end