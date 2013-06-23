class Algorithm::Trilateration < Algorithm::Base

  def set_settings(step = 5, optimization_object)
    @step = step
    @optimization = optimization_object
    self
  end



  private


  def calculate_tags_output(tags = @tags)
    tags_estimates = {}

    antennae_matrix_by_mi = Rails.cache.read('antennae_coefficients_by_mi')
    antennae_matrix_by_algorithm = Rails.cache.read('antennae_coefficients_by_algorithm_tri_ls_'+@reader_power.to_s)

    tags.each do |tag_index, tag|
      distances = MeasurementInformation::Rss.distances_hash(tag.answers[:rss][:average], reader_power)

      decision_function = {}
      distances.each do |antenna_number, distance|
        antenna = @work_zone.antennae[antenna_number]

        (0..@work_zone.width).step(@step) do |x|
          (0..@work_zone.height).step(@step) do |y|
            point = Point.new(x, y)
            decision_function[point] ||= @optimization.default_value_for_decision_function
            value = @optimization.trilateration_criterion_function(point, antenna, distance)
            decision_function[point] = decision_function[point].send(@optimization.method_for_adding, value)

            #if @use_antennae_matrix
            #  coefficient_by_mi = antennae_matrix_by_mi[@reader_power][:rss][antenna_number]
            #  coefficient_by_algorithm = antennae_matrix_by_algorithm[antenna_number]
            #  decision_function[point] /= coefficient_by_mi if antennae_matrix_by_mi.present?
            #  decision_function[point] /= coefficient_by_algorithm if antennae_matrix_by_algorithm.present?
            #end
          end
        end
      end

      decision_function = decision_function.sort_by { |point, value| value }
      decision_function.reverse! if @optimization.reverse_decision_function?

      tag_estimate = make_estimate(decision_function)
      tag_output = TagOutput.new(tag, tag_estimate)
      tags_estimates[tag_index] = tag_output
    end

    tags_estimates
  end


  def make_estimate(pdf)
    max_probability = pdf.map{|e|e.last}.send(@optimization.estimation_extremum_criterion)
    points_to_center = []
    pdf.each do |pdf_element|
      point = pdf_element[0]
      probability = pdf_element[1]
      if probability.send(@optimization.estimation_compare_operator, max_probability)
        points_to_center.push point
      else
        break
      end
    end
    Point.center_of_points(points_to_center)
  end
end