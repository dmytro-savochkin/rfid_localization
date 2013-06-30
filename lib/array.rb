class Array
  def sum
    inject(&:+)
  end

  def mean
    sum.to_f / length
  end

  def stddev
    Math.sqrt( inject(0.0){|sum, el| sum + ((el - mean) ** 2)} / (length - 1) )
  end

  def squares_sum
    average = mean
    map{|element| (element - average) ** 2 }.sum
  end
end