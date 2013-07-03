class Algorithm::Trilateration < Algorithm::Base

  def set_settings(optimization_class, metric_name = :rss, step = 5)
    @step = step
    @metric_name = metric_name
    @mi_class = ('MeasurementInformation::' + metric_name.to_s.capitalize).constantize
    @optimization = optimization_class.new
    self
  end



  def get_decision_function
    decision_functions = {}
    mi = {}

    @tags.each do |tag_index, tag|
      mi_hash = @optimization.optimize_data( tag.answers[@metric_name][:average] )
      distances = @mi_class.distances_hash(mi_hash, reader_power)
      decision_functions[tag_index] = {}
      mi[tag_index] = {
          :mi => tag.answers[@metric_name][:average],
          :filtered => mi_hash,
          :distances => distances
      }
      distances.each do |antenna_number, distance|
        antenna = @work_zone.antennae[antenna_number]
        (0..@work_zone.width).step(@step) do |x|
          (0..@work_zone.height).step(@step) do |y|
            point = Point.new(x, y)
            decision_functions[tag_index][x] ||= {}
            decision_functions[tag_index][x][y] ||= @optimization.default_value_for_decision_function
            value = @optimization.trilateration_criterion_function(point, antenna, distance)
            decision_functions[tag_index][x][y] =
                decision_functions[tag_index][x][y].send(@optimization.method_for_adding, value)
          end
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
    #antennae_matrix_by_mi = Rails.cache.read('antennae_coefficients_by_mi')
    #antennae_matrix_by_algorithm = Rails.cache.read('antennae_coefficients_by_algorithm_tri_ls_'+@reader_power.to_s)
    #if @use_antennae_matrix
    #  coefficient_by_mi = antennae_matrix_by_mi[@reader_power][:rss][antenna_number]
    #  coefficient_by_algorithm = antennae_matrix_by_algorithm[antenna_number]
    #  decision_function[point] /= coefficient_by_mi if antennae_matrix_by_mi.present?
    #  decision_function[point] /= coefficient_by_algorithm if antennae_matrix_by_algorithm.present?
    #end


    tags_estimates = {}

    points_db = create_points_db
    watched_points = []

    start_coord = (@work_zone.width / (2 * @step)).round * @step

    tags.each do |tag_index, tag|
      mi_hash = @optimization.optimize_data( tag.answers[@metric_name][:average] )
      distances = @mi_class.distances_hash(mi_hash, reader_power)

      if distances.length == 1
        antenna_number = distances.keys.first
        antenna_coords = @work_zone.antennae[antenna_number].coordinates
        current_point = points_db[antenna_coords.x][antenna_coords.y] rescue Point.new(antenna_coords.x, antenna_coords.y)
      else
        current_point = points_db[start_coord][start_coord]
        best_total_result = calc_result_for_point(current_point, distances)

        while true
          nearest_points = nearest_coords(points_db, current_point)

          best_nearest_point = nil
          best_nearest_result = nil
          nearest_points.each do |point|
            next if watched_points.include? point
            watched_points.push point
            result = calc_result_for_point(point, distances)

            if best_nearest_point.nil? or result.send(@optimization.gradient_compare_operator, best_nearest_result)
              best_nearest_point = point
              best_nearest_result = result
            end
          end

          if !best_nearest_result.nil? and best_nearest_result.send(@optimization.gradient_compare_operator, best_total_result)
            current_point = best_nearest_point
            best_total_result = best_nearest_result
          else
            break
          end
        end
      end




      tag_output = TagOutput.new(tag, current_point)
      tags_estimates[tag_index] = tag_output
      watched_points = []
    end

    tags_estimates
  end





  def create_points_db
    points_db = {}
    (0..@work_zone.width).step(@step) do |x|
      points_db[x] ||= {}
      (0..@work_zone.height).step(@step) do |y|
        points_db[x][y] = Point.new(x, y)
      end
    end
    points_db
  end

  def nearest_coords(points_db, point)
    nearest_coords = []
    (-@step..@step).step(@step) do |shift_x|
      (-@step..@step).step(@step) do |shift_y|
        x = shift_x.to_i + point.x.to_i
        y = shift_y.to_i + point.y.to_i
        nearest_coords.push points_db[x][y] if Point.coords_correct?(x, y)
      end
    end

    nearest_coords
  end

  def calc_result_for_point(point, distances)
    result = @optimization.default_value_for_decision_function
    distances.each do |antenna_number, distance|
      antenna = @work_zone.antennae[antenna_number]
      value = @optimization.trilateration_criterion_function(point, antenna, distance)
      result = result.send(@optimization.method_for_adding, value)
    end
    result
  end


end