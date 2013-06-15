class Algorithm::Trilateration < Algorithm::Base
  def set_settings(step = 5)
    @step = step
    self
  end



  private


  def calc_errors_for_tags()
    @tags.each do |tag_index, data|
      tag = @tags[tag_index]
      tag.answers[:distances] = rss_hash_to_distances_hash tag.answers[:rss][:average]


      total_decision_function = {}
      tag.answers[:distances].each do |antenna_number, distance|
        antenna = @work_zone.antennae[antenna_number]
        antenna_decision_function = {}

        (0..@work_zone.width).step(@step) do |x|
          (0..@work_zone.height).step(@step) do |y|
            point = Point.new(x, y)
            total_decision_function[point] ||= default_value_for_decision_function
            antenna_decision_function[point] = point_value_for_decision_function(point, antenna, distance)
          end
        end

        antenna_decision_function.each do |point, value|
          total_decision_function[point] = total_decision_function[point].send(method_for_adding, value)
        end
      end
      total_decision_function = total_decision_function.sort_by { |point, value| value }
      total_decision_function.reverse! if reverse_decision_function?

      tag.estimate[@algorithm_name] = make_estimate(total_decision_function)
      tag.error[@algorithm_name] = Point.distance(tag.estimate[@algorithm_name], tag.position)
    end
  end


  def make_estimate(pdf)
    max_probability = pdf.map{|e|e.last}.send estimation_extremum_criterion
    points_to_center = []
    pdf.each do |pdf_element|
      point = pdf_element[0]
      probability = pdf_element[1]
      if probability.send(estimation_compare_operator, max_probability)
        points_to_center.push point
      else
        break
      end
    end
    Point.center_of_points(points_to_center)
  end


  def gaussian(point, antenna, distance)
    sigma_square = 1.8 * (10 ** 7)
    ac = antenna.coordinates

    exp_up = (ac.x - point.x ) ** 2 + ((ac.y + ac.x - point.y - point.x) ** 2) / 1
    exp = (-((exp_up - distance**2) ** 2)) / sigma_square

    Math.exp(exp)
  end


  def rss_hash_to_distances_hash(rss_hash)
    distances_hash = {}
    rss_hash.each do |antenna, rss|
      distances_hash[antenna] = rss_to_distance(rss) if rss > -70.5
    end
    distances_hash
  end


  def rss_to_distance(rss, reader_power = 25)
    rss = (rss.to_f.abs - 61.0).abs
    return 0 if rss < 0
    rss * 5.0

    # 40  101
    # 41  126
    # 42  91
    # 43  132
    # 44  75
    # 45  116
    # 46  127
    # 47  88
    # 48  71
    # 49  96
    # 50  72
    # 51  90
    # 52  79
    # 53  93
    # 54  104
    # 55  117
    # 56  92
    # 57  110
    # 58  102
    # 59  90
    # 60  104
    # 61  103
    # 62  115
    # 63  104
  end
end