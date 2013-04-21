class Trilateration < LocalizationAlgorithm
  attr_accessor :tags_data

  def initialize(work_zone, input_data)
    @work_zone = work_zone
    @tags_data = input_data.values.first.values.first.values.first
    @tags_data.each do |index, data|
      answers = @tags_data[index].answers
      @tags_data[index].answers[:distances] = rss_hash_to_distances_hash @tags_data[index].answers[:rss][:average]



      errors = {}
      (0..work_zone.width).step(100) do |x|
        (0..work_zone.height).step(100) do |y|
          iteration_point = Point.new x, y
          iteration_point.rotate(Math::PI/4)

          errors[iteration_point] = 0.0

          @tags_data[index].answers[:distances].each do |antenna_number, distance|
            antenna = work_zone.antennae[antenna_number]

            shifted_point = iteration_point.dup
            shifted_point.shift(antenna.coordinates.x, antenna.coordinates.y)

            errors[iteration_point] += distance_point_ellipse([distance*1.41, distance], [shifted_point.x, shifted_point.y])
          end
        end
      end


      @tags_data[index].answers[:errors] = errors
    end






    # p distance_point_ellipse([5, 6], [5,0])





  end

  private

  def rss_hash_to_distances_hash(rss_hash)
    distances_hash = {}
    rss_hash.each do |antenna, rss|
      distances_hash[antenna] = rss_to_distance(rss)
    end
    distances_hash
  end

  def rss_to_distance(rss, reader_power = 25)
    (rss.to_f.abs - 60.0) * 5.3
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