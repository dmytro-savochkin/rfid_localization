class Trilateration < LocalizationAlgorithm
  attr_accessor :tags_data, :tags_errors, :cdf_data

  def initialize(work_zone, input_data)
    @work_zone = work_zone
    @tags_data = input_data.values.first.values.first.values.first

    @tags_errors = []

    i = 0
    @tags_data.each do |tag_index, data|
      i += 1
      tag = @tags_data[tag_index]
      tag.answers[:distances] = rss_hash_to_distances_hash tag.answers[:rss][:average]



      total_pdf = {}
      tag.answers[:distances].each do |antenna_number, distance|
        antenna = work_zone.antennae[antenna_number]
        antenna_pdf = {}

        (0..work_zone.width).step(5) do |x|
          (0..work_zone.height).step(5) do |y|
            point = Point.new(x, y)
            total_pdf[point] ||= 1.0
            antenna_pdf[point] = gaussian(point, antenna, distance)
          end
        end


        antenna_pdf.each do |point, probability|
          total_pdf[point] = total_pdf[point] * (probability )
        end
      end


      max = total_pdf.values.max
      total_pdf = total_pdf.sort_by { |point, probability| probability }.reverse







      points_to_center = []
      total_pdf.each do |pdf_element|
        point = pdf_element[0]
        probability = pdf_element[1]
        if probability >= max
          points_to_center.push point
        else
          break
        end
      end

      center_point = center_of_points(points_to_center)




      tag.estimate = center_point
      @tags_errors.push Point.distance(tag.estimate, tag.position)
      tag.answers[:errors] = total_pdf
      @cdf_data = cdf(@tags_errors)




      #break  if i > 50
    end


    # p distance_point_ellipse([5, 6], [5,0])

  end

  private

  def cdf(data)
    size = data.size
    cdf = []
    data.sort.each_with_index {|error, i| cdf.push [(i+1).to_f/size, error]}
    cdf
  end

  def center_of_points(points)
    center = Point.new 0, 0
    points.each do |point|
      center.x += point.x
      center.y += point.y
    end
    center.x /= points.length
    center.y /= points.length
    center
  end

  def gaussian(point, antenna, distance)
    sigma_square = 1.8 * (10 ** 7)
    ac = antenna.coordinates

    # 2.0 => avgerr 98
    # 1.9 => avgerr 99
    # 1.8 => avgerr 66
    # 1.7 => avgerr 109
    # 1.6 => avgerr 67
    # 1.5 => avgerr 89
    # 1.4 => avgerr 89
    # 1.3 => avgerr 82
    # 1.2 => avgerr 96
    # 1.1 => avgerr 80
    # 1.0 => avgerr 96

    #exp_up = (ac.x + ac.y - point.x - point.y) ** 2 + (ac.y - point.y) ** 2
    exp_up = (ac.x - point.x ) ** 2 + ((ac.y + ac.x - point.y - point.x) ** 2) / 1
    #exp_up = (ac.x - point.x ) ** 2 + (ac.y - point.y) ** 2
    exp = (-((exp_up - distance**2) ** 2)) / sigma_square
    result = Math.exp(exp)

    result
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



    # 40   102
    # 41   124
    # 42   94
    # 43   133
    # 44   79
    # 45   117
    # 46   126
    # 47   90
    # 48   77
    # 49   95
    # 50   75
    # 51   89
    # 52   83
    # 53   95
    # 54   103
    # 55   117
    # 56   92
    # 57   109
    # 58   107
    # 59   93
    # 60   105
    # 61   107
    # 62   113
    # 63   106
    # 64   107
    # 65   114

  end
























  def distance_point_ellipse_special(e, y)
    x = []

    if y[1] > 0.0
      if y[0] > 0.0
        esqr = [ e[0]*e[0], e[1]*e[1] ]
        ey = [ e[0]*y[0], e[1]*y[1] ]
        t0 = -esqr[1] + ey[1]
        t1 = -esqr[1] + Math.sqrt(ey[0]*ey[0] + ey[1]*ey[1])
        t = t0
        imax = 2 * (10**9)
        for i in 0...imax
          t = 0.5*(t0 + t1)
          if t == t0 or t == t1
            break
          end

          r = [ ey[0]/(t + esqr[0]), ey[1]/(t + esqr[1]) ]
          f = r[0]*r[0] + r[1]*r[1] - 1.0
          if f > 0.0
            t0 = t
          elsif f < 0.0
            t1 = t
          else
            break
          end
        end

        x[0] = esqr[0]*y[0]/(t + esqr[0])
        x[1] = esqr[1]*y[1]/(t + esqr[1])
        d = [ x[0] - y[0], x[1] - y[1] ]
        distance = Math.sqrt(d[0]*d[0] + d[1]*d[1])
      else
        x[0] = 0.0
        x[1] = e[1]
        distance = (y[1] - e[1]).abs
      end
    else
      denom0 = e[0]*e[0] - e[1]*e[1]
      e0y0 = e[0]*y[0]
      if e0y0 < denom0
        x0de0 = e0y0/denom0
        x0de0sqr = x0de0*x0de0
        x[0] = e[0]*x0de0
        x[1] = e[1]*Math.sqrt((1.0 - x0de0sqr).abs)
        d0 = x[0] - y[0]
        distance = Math.sqrt(d0*d0 + x[1]*x[1])
      else
        x[0] = e[0]
        x[1] = 0.0
        distance = (y[0] - e[0]).abs
      end
    end

    distance
  end


  def distance_point_ellipse (e, y)
    reflect = []

    for i in 0...2
      reflect[i] = (y[i] < 0.0)
    end

    permute = []
    if e[0] < e[1]
      permute[0] = 1
      permute[1] = 0
    else
      permute[0] = 0
      permute[1] = 1
    end

    invpermute = []
    for i in 0...2
      invpermute[permute[i]] = i
    end

    loc_e = []
    loc_y = []
    for i in 0...2
      j = permute[i]
      loc_e[i] = e[j]
      loc_y[i] = y[j]
      loc_y[i] = -loc_y[i] if reflect[j]
    end

    loc_x = []
    distance = distance_point_ellipse_special(loc_e, loc_y)
    #for i in 0...2
      #j = invpermute[i]
      #loc_x[j] = -loc_x[j] if reflect[j]
      #x[i] = loc_x[j]
    #end

    distance
  end


end