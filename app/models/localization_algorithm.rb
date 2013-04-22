class LocalizationAlgorithm
  def cdf(data)
    size = data.size
    cdf = []
    data.sort.each_with_index {|error, i| cdf.push [error, (i+1).to_f/size]}
    cdf
  end
end