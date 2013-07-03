class Optimization::JamesStein < Optimization::LeastSquares

  # positive part James-Stein estimator: http://en.wikipedia.org/wiki/James%E2%80%93Stein_estimator


  def optimize_data(data, mean = nil)
    if data.length >= 3
      optimized_data = {}
      coefficient = [0.0, 1.0 - (data.length - 2).to_f / data.values.squares_sum].max
      mean = data.values.mean if mean.nil?
      data.each do |key, value|
        optimized_data[key] = coefficient * (value - mean) + mean
      end
      optimized_data
    else
      data
    end
  end
end