class Algorithm::Base
  attr_reader :cdf, :map, :average_error, :max_error



  def initialize(input)
    @work_zone = input[:work_zone]
    @tags = input[:tags]
  end


  def set_settings()
  end

  def output()
    calc_errors_for_tags

    errors = @tags.values.map{|tag| tag.error}

    @average_error = (errors.inject(0.0) { |sum, el| sum + el } / errors.size).round(1)
    @max_error = errors.max.round(1)
    @cdf = create_cdf(errors)

    @map = {}
    @tags.each {|id, value| @map[id] = {:position => value.position, :estimate => value.estimate} }

    self
  end


  private

  def create_cdf(data)
    size = data.size
    cdf = []
    data.sort.each_with_index {|error, i| cdf.push [error, (i+1).to_f/size]}
    cdf
  end
end