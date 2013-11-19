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


  def self.rv_coefficient(points_array1, points_array2)
    raise Exception('vectors length does not match') if points_array1.length != points_array2.length
    nominator = 0.0

    squares1 = 0.0
    squares2 = 0.0

    (0...points_array1.length).each do |i|
      point1 = points_array1[i]
      point2 = points_array2[i]

      (0..1).each do |j|
        nominator += point1[j] * point2[j]
        squares1 += point1[j] ** 2
        squares2 += point2[j] ** 2
      end
    end

    denominator = Math.sqrt(squares1 * squares2)


    #puts nominator.to_s
    #puts denominator.to_s

    nominator / denominator
  end


  def self.brownian_correlation(points_array1, points_array2)
    if points_array1.length != points_array2.length
      raise Exception.new('vectors length does not match')
    end

    columns_means1 = []
    columns_means2 = []
    rows_means1 = []
    rows_means2 = []

    points_array1.each do |point1|
      rows_means1.push(point1.mean)
    end
    columns_means1[0] = points_array1.map{|p| p[0]}.mean
    columns_means1[1] = points_array1.map{|p| p[1]}.mean

    points_array2.each do |point2|
      rows_means2.push(point2.mean)
    end
    columns_means2[0] = points_array2.map{|p| p[0]}.mean
    columns_means2[1] = points_array2.map{|p| p[1]}.mean

    total_mean1 = points_array1.flatten.mean
    total_mean2 = points_array2.flatten.mean


    calc_covariance = ->(array1, array2, means1, means2) do
      covariance = 0.0
      (0...array1.length).each do |i|
        point1 = array1[i]
        point2 = array2[i]
        (0..1).each do |j|
          a = point1[j] - means1[:rows][i] - means1[:columns][j] + means1[:total]
          b = point2[j] - means2[:rows][i] - means2[:columns][j] + means2[:total]
          covariance += a * b
        end
      end
      covariance /= 2 * (array1.length)
      Math.sqrt(covariance)
    end


    means1 = {:rows => rows_means1, :columns => columns_means1, :total => total_mean1}
    means2 = {:rows => rows_means2, :columns => columns_means2, :total => total_mean2}

    covariance = calc_covariance.call(points_array1, points_array2, means1, means2)
    x_covariance = calc_covariance.call(points_array1, points_array1, means1, means1)
    y_covariance = calc_covariance.call(points_array2, points_array2, means2, means2)

    covariance / Math.sqrt(x_covariance * y_covariance)
  end



  # http://en.wikipedia.org/wiki/Rayleigh_distribution (Generating random variates)
  def self.rayleigh_value(sigma)
    uniform_distribution_value = rand()
    sigma.to_f * Math.sqrt(-2.0 * Math.log(uniform_distribution_value))
  end





  #def self.newton_rr_nonlinear_equation(params)
  #  function_derivative = ->(value) do
  #    result = 0.0
  #    params.each_with_index do |param, i|
  #      result += param * i * (value ** (i - 1)) if i >= 1
  #    end
  #    result
  #  end
  #
  #  #puts function_derivative.call(50)
  #
  #  function_value = ->(value) do
  #    result = 0.0
  #    params.each_with_index do |param, i|
  #      result += param * (value ** i)
  #    end
  #    result
  #  end
  #
  #  eps = 10e-6
  #  stop_eps = 10e-4
  #  x = 0.5
  #
  #  stack = []
  #
  #  until (function_value.call(x)).abs < eps and x >= 0.0 and x <= 1.0
  #    x = x - function_value.call(x) / function_derivative.call(x)
  #    stack.push x
  #    if stack.select{|v| (v - x).abs < stop_eps}.length > 4
  #      x = 0.0 if x >= 0.0 and x <= 1.0
  #      break
  #    end
  #    puts x.to_s + ' ' + function_value.call(x).to_s + ' ' + eps.to_s
  #  end
  #
  #  x
  #end

end
