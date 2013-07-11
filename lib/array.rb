class Array
  def mode
    max = 0
    c = Hash.new 0
    each {|x| cc = c[x] += 1; max = cc if cc > max}
    c.select {|k,v| v == max}.map {|k,v| k}
  end

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