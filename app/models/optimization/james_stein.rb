class Optimization::JamesStein < Optimization::LeastSquares

  # positive part James-Stein estimator: http://en.wikipedia.org/wiki/James%E2%80%93Stein_estimator


  def optimize_data(data)
    if data.length >= 3
      antennae_count = 16
      coefficient = [0.0, 1.0 - (antennae_count - 2).to_f / data.values.squares_sum].max
      mean = data.values.mean
      data.each do |key, value|
        data[key] = coefficient * (value - mean) + mean
      end
    end
    data
  end



  def optimization_data(data)
    #antennae_count = 16
    #coefficient = 1.0 - (antennae_count - 2).to_f / data.values.squares_sum
    #coefficient = 0.0 if coefficient < 0
    #{
    #  :length => data.length,
    #  :mean => data.values.mean,
    #  :coefficient => coefficient
    #}
    {}
  end


  def trilateration_criterion_function(point, antenna, distance, distances)
    ac = antenna.coordinates
    antenna_to_tag_distance = Math.sqrt((ac.x - point.x)**2 + (ac.y - point.y)**2)


    #if distances.present? and distances[:length] >= 3
    #  estimated_distance = distances[:coefficient] * (distance - distances[:mean]) + distances[:mean]
    #else
    #  estimated_distance = distance
    #end


    criterion_function(antenna_to_tag_distance, distance)
  end
end