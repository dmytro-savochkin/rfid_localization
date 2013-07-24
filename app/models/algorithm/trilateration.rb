class Algorithm::Trilateration < Algorithm::Base

  def set_settings(optimization_class, metric_name = :rss, step = 5)
    @step = step
    @metric_name = metric_name
    @mi_class = MeasurementInformation::Base.class_by_mi_type(metric_name)
    @optimization = optimization_class.new
    @regression_type = 'new'
    self
  end





  def get_decision_function
    decision_functions = {}
    mi = {}

    @tags.each do |tag_index, tag|
      mi_hash = @optimization.optimize_data( tag.answers[@metric_name][:average] )
      decision_functions[tag_index] = {}
      mi[tag_index] = {
          :mi => tag.answers[@metric_name][:average],
          :filtered => mi_hash
      }

      (0..@work_zone.width).step(@step) do |x|
        (0..@work_zone.height).step(@step) do |y|
          point = Point.new(x, y)
          distances = get_distances_cache(mi_hash, point)
          decision_functions[tag_index][x] ||= {}
          decision_functions[tag_index][x][y] = calc_result_for_point(point, distances)
        end
      end
    end

    {
        :mi => mi,
        :extremum_criterion => @optimization.estimation_extremum_criterion,
        :data => decision_functions
    }
  end












  private



  def calculate_tags_output(tags = @tags)
    tags_estimates = {}



    n = 10
    Benchmark.bm(7) do |x|
      x.report('trilateration') do
        n.times do


          start_coord = (@work_zone.width.to_f / (2 * @step.to_f)).round * @step

          tags.each do |tag_index, tag|
            mi_hash = @optimization.optimize_data( tag.answers[@metric_name][:average] )

            if mi_hash.length == 1
              current_point = point_for_one_antenna_case(mi_hash)
            elsif mi_hash.length == 2
              current_point = point_for_two_antennae_case(mi_hash)
            else
              current_point = Point.new(start_coord, start_coord)
              previous_point_result = 0.0

              while true
                current_point_result = calc_result_for_point(current_point, get_distances_cache(mi_hash, current_point))
                break if (current_point_result - previous_point_result).abs < @optimization.epsilon
                previous_point_result = current_point_result

                current_point = next_point_via_gradient(current_point, current_point_result, mi_hash)
                break if current_point.nil?
              end

            end

            tag_output = TagOutput.new(tag, current_point)
            tags_estimates[tag_index] = tag_output
          end

        end
      end
    end


    tags_estimates
  end





  def next_point_via_gradient(point, current_point_result, mi_hash)
    gradient_step = 0.1

    nearest_points = calc_nearest_points(point, gradient_step)
    nearest_points_results = nearest_points.map do |p|
      calc_result_for_point(p, get_distances_cache(mi_hash, p))
    end

    coeff_x = (nearest_points_results[0] - current_point_result) / gradient_step
    coeff_y = (nearest_points_results[1] - current_point_result) / gradient_step
    angle = Math.atan2(coeff_y, coeff_x)
    angle = opposite_angle(angle) unless @optimization.reverse_decision_function?

    next_point = one_dimensional_optimization(point, angle, mi_hash)

    return nil if next_point.x > WorkZone::WIDTH or next_point.y > WorkZone::HEIGHT
    next_point
  end


  def opposite_angle(angle)
    if angle < 0.0
      angle + Math::PI
    else
      angle - Math::PI
    end
  end


  def one_dimensional_optimization(start_point, angle, mi_hash)
    width = WorkZone::WIDTH
    height = WorkZone::HEIGHT

    distance_epsilon = 2.0

    if angle.between?(0, Math::PI/2) # 1
      angle_parameters = [Math.cos(angle), Math.sin(angle)]
      a = [width - start_point.x, height - start_point.y]
      angles = [angle, Math::PI/2 - angle]
    elsif angle.between?(Math::PI/2, Math::PI) # 2
      new_angle = Math::PI - angle
      angle_parameters = [- Math.cos(new_angle), Math.sin(new_angle)]
      a = [start_point.x, height - start_point.y]
      angles = [Math::PI - angle, angle - Math::PI/2]
    elsif angle.between?(-Math::PI/2, 0) # 3
      new_angle = angle.abs
      angle_parameters = [Math.cos(new_angle), - Math.sin(new_angle)]
      a = [width - start_point.x, start_point.y]
      angles = [angle.abs, Math::PI/2 - angle.abs]
    else # 4
      new_angle = Math::PI - angle.abs
      angle_parameters = [- Math.cos(new_angle), - Math.sin(new_angle)]
      a = [start_point.x, start_point.y]
      angles = [Math::PI - angle.abs, angle.abs - Math::PI/2]
    end

    hypotenuse = [a[0] / Math.cos(angles[0]), a[1] / Math.cos(angles[1])].min

    end_point = point_by_ray(start_point, hypotenuse, angle_parameters)

    a = start_point
    b = end_point



    while true
      center = Point.center_of_points([a,b])
      distance = Point.distance(a, center)

      x1 = point_by_ray(a, 0.99 * distance, angle_parameters)
      x2 = point_by_ray(a, 1.01 * distance, angle_parameters)
      y1 = calc_result_for_point(x1, get_distances_cache(mi_hash, x1))
      y2 = calc_result_for_point(x2, get_distances_cache(mi_hash, x2))

      if y2.send(@optimization.gradient_compare_operator, y1)
        a = x1
      else
        b = x2
      end

      if Point.distance(b, a).abs < distance_epsilon
        return Point.center_of_points([a, b])
      end
    end

  end

  def point_by_ray(start, hypotenuse, angle_parameters)
    Point.new( start.x + hypotenuse * angle_parameters[0], start.y + hypotenuse * angle_parameters[1] )
  end


  def calc_nearest_points(point, step)
    nearest_points = [point.dup, point.dup]
    nearest_points[0].x += step
    nearest_points[1].y += step
    return nil if nearest_points.any?{|p| p.nil?}
    nearest_points
  end




  def calc_result_for_point(point, distances)
    @results ||= {}
    cache_name = point.to_s + distances.to_s
    return @results[cache_name] if @results[cache_name].present?

    real_distances = {}
    distances.keys.map do |antenna_number|
      antenna = @work_zone.antennae[antenna_number]
      ac = antenna.coordinates
      real_distances[antenna_number] = Math.sqrt((ac.x.to_f - point.x) ** 2 + (ac.y.to_f - point.y) ** 2)
    end

    @results[cache_name] = @optimization.compare_vectors(
        real_distances,
        distances,
        double_sigma_power
    )
    @results[cache_name]
  end


  def get_distances_cache(mi_hash, point)
    @mi_class.distances_hash(mi_hash, @mi_class.angles_hash(mi_hash, point), @reader_power, @regression_type)
  end




  def double_sigma_power
    return 10_000 if @metric_name == :rss
    return 2 if @metric_name == :rr
    nil
  end














  def point_for_one_antenna_case(mi_hash)
    antenna_number = mi_hash.keys.first
    antenna = @work_zone.antennae[antenna_number]
    antenna_coords = antenna.coordinates

    if antenna.near_walls?
      mi_range = [60.0, 73.0] if @metric_name == :rss
      mi_range = [0.0, 1.0] if @metric_name == :rr

      difference = mi_range[1] - mi_range[0]
      mi = mi_hash.values.first.abs
      weights = []
      if mi < mi_range[1]
        weights = [(mi_range[1] - mi).abs / difference, (mi - mi_range[0]).abs / difference]
      end
      antenna_coords = Point.center_of_points([antenna_coords, antenna.nearest_wall_point], weights)
    end

    Point.new(antenna_coords.x, antenna_coords.y)
  end

  def point_for_two_antennae_case(mi_hash)
    min = 60.0 if @metric_name == :rss
    min = 0.0 if @metric_name == :rr

    antennae_coords = @work_zone.antennae.select{|n,a|mi_hash.keys.include? n}.values.map{|a| a.coordinates}
    mi_array = mi_hash.values.map(&:abs)

    total = mi_array.sum - 2 * min

    weights = []
    if min < mi_array.min
      weights = [(mi_array[1] - min).abs.to_f / total, (mi_array[0] - min).abs.to_f / total]
    end

    center = Point.center_of_points(antennae_coords, weights)
    Point.new(center.x, center.y)
  end







end