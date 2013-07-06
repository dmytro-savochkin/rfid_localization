class Optimization::JamesStein < Optimization::LeastSquares

  # positive part James-Stein estimator: http://en.wikipedia.org/wiki/James%E2%80%93Stein_estimator


  def optimize_data(data, mean = nil)
    if data.length >= 3
      keys = nil
      if data.class == Hash
        keys = data.keys
        values = data.values
      elsif data.class == Array
        values = data
      else
        raise Exception('Wrong data type')
      end
      optimized_data = {}
      coefficient = [0.0, 1.0 - (data.length - 2).to_f / values.squares_sum].max
      mean = values.mean if mean.nil?
      values.each_with_index do |value, index|
        key = keys[index] rescue index
        optimized_value = coefficient * (value - mean) + mean
        optimized_data[key] = optimized_value
      end
      if data.class == Hash
        optimized_data
      else
        optimized_data.values
      end
    else
      data
    end
  end
end