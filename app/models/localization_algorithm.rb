class LocalizationAlgorithm
  attr_accessor :cdf, :map, :average_error

  def initialize()
    @work_zone = WorkZone.new
    @tags = Parser.parse.values.first.values.first.values.first
    self
  end

  def set_settings()
  end

  def output()
    calc_errors_for_tags

    errors = @tags.values.map{|tag| tag.error}

    @average_error = errors.inject(0.0) { |sum, el| sum + el } / errors.size
    @cdf = create_cdf(errors)

    @map = [
        @tags.values.map{|tag| tag.position.to_a},
        @tags.values.map{|tag| tag.estimate.to_a}
    ]
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