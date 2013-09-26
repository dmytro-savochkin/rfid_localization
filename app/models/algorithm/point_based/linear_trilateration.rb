class Algorithm::PointBased::LinearTrilateration < Algorithm::PointBased::Trilateration

  def set_settings(metric_name, optimization_class, model_type, rr_limit, ellipse_ratio, normalization)
    @metric_name = metric_name
    @metric_type = :average
    @mi_class = MI::Base.class_by_mi_type(metric_name)
    @optimization = optimization_class.new
    @model_type = model_type
    @rr_limit = rr_limit

    @ellipse_ratio = ellipse_ratio
    @normalization = normalization

    @step = 5.0

    self
  end





  def get_decision_function
    decision_functions = {}
    mi = {}
    test_height = 0

    @tags_input[test_height].each do |tag_index, tag|
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










  def model_run_method(height, tag)
    mi_hash = tag.answers[@metric_name][@metric_type]
    mi_hash = mi_hash.dup.keep_if{|k,v| tag.answers[:rr][:average][k] > @rr_limit}
    mi_hash = tag.answers[@metric_name][:average] if mi_hash.empty?
    decision_functions = {}

    #puts tag.id.to_s

    if mi_hash.length == 1
      point_for_one_antenna_case(mi_hash)
      #Point.new(nil,nil)
    elsif mi_hash.length == 2
      point_for_two_antennae_case(mi_hash)
      #Point.new(nil,nil)
    else
      polygon = mi_hash.keys.map{|a| @work_zone.antennae[a].coordinates}

      points = Rails.cache.fetch('polygon_points_'+polygon.sort_by{|p| [p.x, p.y]}.to_s + @step.to_s, :expires_in => 5.day) do
        Point.points_in_polygon(polygon, @step)
      end

      points.each do |point|
        decision_functions[point] = calc_result_for_point(point, mi_hash)
      end

      decision_functions.sort_by{|point, v| v}.first.first
    #else
    #  Point.new(nil,nil)
    end
  end







  private






  def calc_result_for_point(point, mi_hash)
    d_max = 100.0

    range = @mi_class.range
    range = [-55.0, -75.0] if @metric_name == :rss

    max_antenna_number = mi_hash.sort_by{|a, mi| mi.abs}.first.first
    max_antenna = @work_zone.antennae[max_antenna_number]

    normalized_distances = {}
    normalized_mi = {}

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

      normalized_distances[antenna_number] = d1

      if @normalization == :local_maximum
        normalized_mi[antenna_number] = d0 * (range[0] - mi1) / (range[0] - mi0)
        normalized_mi[antenna_number] *= e1 / e0 if @model_type == :ellipse
      elsif @normalization == :global_maximum
        normalized_mi[antenna_number] = d_max * (range[0] - mi1) / (range[0] - range[1])
        normalized_mi[antenna_number] *= e1 if @model_type == :ellipse
      end
    end

    @optimization.compare_vectors(
        normalized_distances,
        normalized_mi,
        {},
        double_sigma_power
    )
  end






  def antenna_point_angle(antenna, point)
    ac = antenna.coordinates
    angle = Math.atan2(point.y - ac.y, point.x - ac.x)
    angle = opposite_angle(angle) unless @optimization.reverse_decision_function?
    angle
  end

end