module Math
  def self.correlation(x_array, y_array)
    raise Exception('vectors length does not match') if x_array.length != y_array.length

    x_mean = x_array.mean
    y_mean = y_array.mean

    nominator = 0.0
    denominator_first_part = 0.0
    denominator_second_part = 0.0
    x_array.each_with_index do |x, i|
      y = y_array[i]
      nominator += (x - x_mean) * (y - y_mean)
      denominator_first_part += (x - x_mean) ** 2
      denominator_second_part += (y - y_mean) ** 2
    end

    denominator = Math.sqrt(denominator_first_part * denominator_second_part)
    nominator / denominator
  end



  # http://en.wikipedia.org/wiki/Rayleigh_distribution (Generating random variates)
  def self.rayleigh_value(sigma)
    uniform_distribution_value = rand()
    sigma.to_f * Math.sqrt(-2.0 * Math.log(uniform_distribution_value))
  end

end
