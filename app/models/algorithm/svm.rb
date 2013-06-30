class Algorithm::Svm < Algorithm::Base

  def set_settings(metric_name = :rss, tags_for_table)
    @metric_name = metric_name
    @tags_for_table = tags_for_table
    @points_to_zones = {}
    self
  end



  private


  def calculate_tags_output(tags = @tags)
    tags_estimates = {}

    svm_model = train_svm_model

    tags.each do |tag_index, tag|
      tag_mi_answers = (1..16).map{|antenna| tag.answers[@metric_name][:average][antenna] || default_table_value}

      zone_estimate = svm_model.predict(Libsvm::Node.features(*tag_mi_answers))
      tag_estimate = @points_to_zones.select{|point, zone_num| zone_num == zone_estimate}.keys.first

      tag_output = TagOutput.new(tag, tag_estimate)
      tags_estimates[tag_index] = tag_output
    end

    tags_estimates
  end

  def train_svm_model
    svm_problem = Libsvm::Problem.new
    svm_parameter = Libsvm::SvmParameter.new
    svm_parameter.cache_size = 1 # in megabytes
    svm_parameter.eps = 0.0001
    svm_parameter.c = 10

    train_input = []
    train_output = []
    @tags_for_table.values.each do |tag|
      mi_answers = (1..16).map{|antenna| tag.answers[@metric_name][:average][antenna] || default_table_value}
      train_input.push Libsvm::Node.features(mi_answers)

      unless @points_to_zones.include? tag.position
        @points_to_zones[tag.position] = @points_to_zones.length + 1
      end
      train_output.push @points_to_zones[tag.position]
    end

    svm_problem.set_examples(train_output, train_input)
    Libsvm::Model.train(svm_problem, svm_parameter)
  end




  def create_data_table(current_tag_index)
    if @tags_for_table.empty?
      tags = @tags.except(current_tag_index)
    else
      tags = @tags_for_table
    end

    table = {:data => {}, :results => {}}
    tags.each do |index, tag|
      table[:data][tag.position] = tag.answers[@metric_name][:average]
    end

    table
  end



  def default_table_value
    return -75.0 if @metric_name == :rss
    return 0.0 if @metric_name == :rr
    nil
  end
end