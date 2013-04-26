class Trilateration < LocalizationAlgorithm
  def set_settings(step = 50)
    @step = step
    self
  end




  private


  def calc_errors_for_tags()
    @tags.each do |tag_index, data|
      tag = @tags[tag_index]
      tag.answers[:distances] = rss_hash_to_distances_hash tag.answers[:rss][:average]


      total_pdf = {}
      tag.answers[:distances].each do |antenna_number, distance|
        antenna = @work_zone.antennae[antenna_number]
        antenna_pdf = {}

        (0..@work_zone.width).step(@step) do |x|
          (0..@work_zone.height).step(@step) do |y|
            point = Point.new(x, y)
            total_pdf[point] ||= 1.0
            antenna_pdf[point] = gaussian(point, antenna, distance)
          end
        end

        antenna_pdf.each do |point, probability|
          total_pdf[point] = total_pdf[point] * (probability )
        end
      end
      total_pdf = total_pdf.sort_by { |point, probability| probability }.reverse

      tag.estimate = make_estimate(total_pdf)
      tag.error = Point.distance(tag.estimate, tag.position)
    end
  end


  def make_estimate(pdf)
    max_probability = pdf.map{|e|e.last}.max
    points_to_center = []
    pdf.each do |pdf_element|
      point = pdf_element[0]
      probability = pdf_element[1]
      if probability >= max_probability
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
      distances_hash[antenna] = rss_to_distance(rss)
    end
    distances_hash
  end


  def rss_to_distance(rss, reader_power = 25)
    rss = (rss.to_f.abs - 60.0)
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