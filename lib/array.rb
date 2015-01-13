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

  def general_product
    inject(&:*)
  end

  def variance
    inject(0.0){|sum, el| sum + ((el - mean) ** 2)} / (length - 1)
  end

  def stddev
    Math.sqrt(variance)
  end

  def points_stddev
    center = Point.center_of_points(self)
    distances = map{|point| Point.distance(point, center)}
    distances.mean
  end

  def squares_sum
    average = mean
    map{|element| (element - average) ** 2 }.sum
  end


  def frequency
    freq = {}
    self.uniq.each do |elem|
      freq[elem] = self.select{|e|e == elem}.length
    end
    freq
	end

	def deep_dup
		copy = []
		self.each do |e|
			copy.push e.dup
		end
		copy
	end


	def except(value)
		self - [value]
	end
end