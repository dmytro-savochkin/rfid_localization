module Math
  def self.covariance(x_array, y_array)
    raise Exception('vectors length does not match') if x_array.length != y_array.length
    x_mean = x_array.mean
    y_mean = y_array.mean

    covariance = 0.0
    x_array.each_with_index do |x, i|
      y = y_array[i]
      covariance += (x - x_mean) * (y - y_mean)
    end
    covariance / x_array.length
  end

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

    points_array1 = points_array1.map{|a|a.map{|v|v.to_f}}
    points_array2 = points_array2.map{|a|a.map{|v|v.to_f}}

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


  # http://en.wikipedia.org/wiki/Distance_correlation#Distance_covariance
  def self.brownian_correlation(points_array1, points_array2)
    if points_array1.length != points_array2.length
      raise Exception.new('vectors length does not match')
    end
    array1 = points_array1.map{|a|a.map{|v|v.to_f}}
    array2 = points_array2.map{|a|a.map{|v|v.to_f}}

    #puts array1.to_s
    #puts array2.to_s

    a = []
    b = []
    (0...array1.length).each do |i|
      a[i] ||= []
      b[i] ||= []
      (0...array1.length).each do |j|
        a[i][j] = sqrt((array1[i][0] - array1[j][0])**2 + ((array1[i][1] - array1[j][1])**2))
        b[i][j] = sqrt((array2[i][0] - array2[j][0])**2 + ((array2[i][1] - array2[j][1])**2))
      end
    end

    #puts a.to_s
    #puts b.to_s

    rows = {:a => [], :b => []}
    columns = {:a => [], :b => []}
    (0...array1.length).each do |i|
      rows[:a][i] = a[i].mean
      rows[:b][i] = b[i].mean
      columns[:a][i] = a.map{|v| v[i]}.mean
      columns[:b][i] = b.map{|v| v[i]}.mean
    end
    means = {:a => a.flatten.mean, :b => b.flatten.mean}

    #puts rows.to_s
    #puts columns.to_s
    #puts means.to_s

    a_big = []
    b_big = []
    sum = 0.0
    x_stddev = 0.0
    y_stddev = 0.0
    (0...array1.length).each do |i|
      a_big[i] ||= []
      b_big[i] ||= []
      (0...array1.length).each do |j|
        a_big[i][j] = a[i][j] - rows[:a][i] - columns[:a][j] + means[:a]
        b_big[i][j] = b[i][j] - rows[:b][i] - columns[:b][j] + means[:b]
        sum += a_big[i][j] * b_big[i][j]
        x_stddev += a_big[i][j] * a_big[i][j]
        y_stddev += b_big[i][j] * b_big[i][j]
      end
    end

    covariance = sum / (array1.length ** 2)
    x_stddev = sqrt( x_stddev / (array1.length ** 2))
    y_stddev = sqrt( y_stddev / (array1.length ** 2))

    correlation = covariance / (x_stddev * y_stddev)

    #puts covariance.to_s
    #puts x_stddev.to_s
    #puts y_stddev.to_s

    correlation
  end



  # http://en.wikipedia.org/wiki/Rayleigh_distribution (Generating random variates)
  def self.rayleigh_value(sigma)
    uniform_distribution_value = rand()
    sigma.to_f * Math.sqrt(-2.0 * Math.log(uniform_distribution_value))
  end









  def self.quadratic_roots(coeffs)
    require 'cmath'
    raise Exception.new('wrong number of coefficients for quadratic polynomial') if coeffs.length != 3
    a = coeffs[0].to_f
    b = coeffs[1].to_f
    c = coeffs[2].to_f

    big_d = CMath.sqrt(b**2 - 4.0*a*c)
    x1 = (-b+big_d)/(2.0*a)
    x2 = (-b-big_d)/(2.0*a)
    [x1, x2].map{|x| if x.imaginary == 0.0 then x.real else x end }
  end


  # http://en.wikipedia.org/wiki/Cubic_function#General_formula_for_roots
  def self.cubic_roots(coeffs)
    require 'cmath'
    raise Exception.new('wrong number of coefficients for cubic polynomial') if coeffs.length != 4
    a = coeffs[0].to_f
    b = coeffs[1].to_f
    c = coeffs[2].to_f
    d = coeffs[3].to_f

    i = CMath.sqrt(-1.0)

    u1 = 1.0
    u2 = (-1.0 + i*CMath.sqrt(3.0)) / 2.0
    u3 = (-1.0 - i*CMath.sqrt(3.0)) / 2.0

    delta = 18.0*a*b*c*d - 4.0*b**3*d + b**2*c**2 - 4.0*a*c**3 - 27.0*a**2*d**2
    delta0 = b**2 - 3.0*a*c
    delta1 = 2.0*b**3 - 9.0*a*b*c + 27.0*a**2*d


    #puts delta.to_s
    #puts delta0.to_s
    #puts delta1.to_s
    #puts u2.to_s
    #puts u3.to_s

    if delta == 0.0 and delta0 == 0.0
      root = -b/(3.0*a)
      return [root, root, root]
    end

    if delta != 0.0 and delta0 == 0.0
      puts 'strange case!!!'
      big_c = CMath.cbrt((delta1 + CMath.sqrt(2*delta1**2))/2.0)
    else
      big_c = CMath.cbrt((delta1 + CMath.sqrt(delta1**2 - 4.0*delta0**3))/2.0)
    end

    root = ->(u) do
      u_big_c = u*big_c
      -(b + u_big_c + delta0/u_big_c)/(3.0*a)
    end

    [root.call(u1), root.call(u2), root.call(u3)].map{|x| if x.imaginary == 0.0 then x.real else x end }
  end

  # http://en.wikipedia.org/wiki/Quartic_function#General_formula_for_roots
  def self.quartic_roots(coeffs)
    require 'cmath'
    raise Exception.new('wrong number of coefficients for quartic polynomial') if coeffs.length != 5
    a = coeffs[0].to_f
    b = coeffs[1].to_f
    c = coeffs[2].to_f
    d = coeffs[3].to_f
    e = coeffs[4].to_f

    p = (8.0*a*c - 3.0*b**2) / (8.0*a**2)
    q = (b**3 - 4.0*a*b*c + 8.0*a**2*d) / (8.0*a**3)

    delta0 = c**2 - 3.0*b*d + 12.0*a*e
    delta1 = 2*c**3 - 9.0*b*c*d + 27.0*b**2*e + 27.0*a*d**2 - 72*a*c*e

    big_q = CMath.cbrt( (delta1 + CMath.sqrt(delta1**2 - 4*delta0**3)) / 2.0 )
    big_s = 0.5 * CMath.sqrt(-2.0*p/3 + (big_q + delta0/big_q)/(3.0*a))

    last_part1 = 0.5 * CMath.sqrt(-4.0*big_s**2 - 2*p + q/big_s)
    last_part2 = 0.5 * CMath.sqrt(-4.0*big_s**2 - 2*p - q/big_s)
    x1 = -b/(4.0*a) - big_s + last_part1
    x2 = -b/(4.0*a) - big_s - last_part1
    x3 = -b/(4.0*a) + big_s + last_part2
    x4 = -b/(4.0*a) + big_s - last_part2
    [x1, x2, x3, x4].map{|x| if x.imaginary == 0.0 then x.real else x end }
  end


  def self.linear_roots(coeffs)
    # 0 = ax + b
    a = coeffs[0].to_f
    b = coeffs[1].to_f
    [-b/a]
  end

  def self.roots(coeffs)
    case coeffs.length
      when 2
        linear_roots(coeffs)
      when 3
        quadratic_roots(coeffs)
      when 4
        cubic_roots(coeffs)
      when 5
        quartic_roots(coeffs)
      else
        raise Exception.new('unsupported number of equation coefficients')
    end
  end

  def self.filter_for_real_roots(roots)
    eps = 0.001
    real_roots = roots.select{|x| x.real? or x.imaginary.abs < eps}.map{|x| x.real}
    if real_roots.empty?
      [roots.sort_by{|v| v.imaginary.abs}.first.real]
    else
      real_roots
    end
  end



  def self.polynomial_coefficients_by_roots(roots)
    coeffs = [1.0]
    (1..roots.length).each do |k|
      coeff = roots.combination(k).map{|a| a.general_product}.sum
      coeff *= -1 if k.odd?
      coeffs.push coeff
    end
    coeffs
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



	def self.bilinear_interpolation(point, node_points_values_hash)
		node_points = node_points_values_hash.keys.map{|point_s| Point.from_s(point_s)}

		node_points.each do |node_point|
			if node_point.to_s == point.to_s
				return node_points_values_hash[node_point.to_s]
			end
		end

		points_to_find_nearest = []
		points_to_find_nearest.push node_points.select{|p| p.y >= point.y and p.x <= point.x}
		points_to_find_nearest.push node_points.select{|p| p.y >= point.y and p.x > point.x}
		points_to_find_nearest.push node_points.select{|p| p.y < point.y and p.x <= point.x}
		points_to_find_nearest.push node_points.select{|p| p.y < point.y and p.x > point.x}
		nearest_node_points = []
		points_to_find_nearest.each do |point_group|
			nearest_node_points.push( point_group.sort_by{|p| Point.distance(point, p)}.first )
		end
		nearest_node_points.reject!(&:nil?)

		distances = []
		nearest_node_points.each{|p| distances.push(Point.distance(point, p))}
		nearest_node_points_coeffs = []
		inverted_distances_sum = distances.map{|d| 1.0 / d }.sum
		distances.each do |distance|
			nearest_node_points_coeffs.push( (1.0 / distance) / inverted_distances_sum )
		end

		nearest_node_points.map.with_index do |nearest_node_point, i|
			nearest_node_points_coeffs[i] *  node_points_values_hash[nearest_node_point.to_s]
		end.sum
	end
end
