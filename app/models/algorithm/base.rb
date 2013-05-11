class Algorithm::Base
  attr_reader :cdf, :map, :mean_error, :max_error, :min_error, :show_in_chart, :tags
  attr_accessor :best_suited_for



  def initialize(input, algorithm_name, show_in_chart = true)
    @algorithm_name = algorithm_name
    @work_zone = input[:work_zone]
    @tags = input[:tags]
    @show_in_chart = show_in_chart
  end


  def set_settings()
  end

  def output()
    calc_errors_for_tags

    tags_errors = @tags.values.select{|tag| tag unless tag.error[@algorithm_name].nil?}.map{|tag| tag.error[@algorithm_name]}

    @mean_error = (tags_errors.inject(0.0) do |sum, el|
      next sum if el.nil?
      sum + el
    end / tags_errors.size).round(1)
    @max_error = tags_errors.max.round(1)
    @min_error = tags_errors.min.round(1)
    @cdf = create_cdf(tags_errors)

    @map = {}
    @tags.each do |tag_id, tag|
      unless tag.estimate[@algorithm_name].nil?
        @map[tag_id] = {
            :position => tag.position,
            :estimate => tag.estimate[@algorithm_name],
            :error => tag.error[@algorithm_name],
            :answers_count => tag.answers_count,
        }
      end
    end

    @best_suited_for = create_best_suited_hash

    self
  end


  private

  def create_best_suited_hash
    hash = {:all => {:percent => 0.0, :total => Tag.tag_ids.size}}
    (1..16).each {|antennae_count| hash[antennae_count] = {:percent => 0.0, :total => nil}}
    hash
  end

  def create_cdf(data)
    size = data.size
    cdf = []
    data.sort.each_with_index {|error, i| cdf.push [error, (i+1).to_f/size]}
    cdf
  end
end