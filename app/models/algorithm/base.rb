class Algorithm::Base

  def initialize(input, train_data)
    @work_zone = input[:work_zone]
    @reader_power = input[:reader_power]
    @tags_input = train_data
  end

  def set_settings(metric_name)
    @metric_name = metric_name
    @mi_class = MI::Base.class_by_mi_type(metric_name)
    self
  end


  #def initialize(input, compare_by_antennae = true, show_in_chart = {:main => true, :histogram => true},
  #    use_antennae_matrix = true)
  #  @work_zone = input[:work_zone]
  #  @tags_test_input = input[:tags_test_input]
  #  @reader_power = input[:reader_power]
  #  @compare_by_antennae = compare_by_antennae
  #  @show_in_chart = show_in_chart
  #  @use_antennae_matrix = use_antennae_matrix
  #end






  private


  def execute_tags_estimates_search(models, train_height, test_height)
    calc_tags_estimates(models[train_height], @tags_input[test_height])
  end



  def tag_answers_empty_hash
    answers = {}
    (1..16).each{|antenna| answers[antenna] = @mi_class.default_value}
    answers
  end

  def tag_answers_hash(tag)
    answers = {}
    (1..16).each{|antenna| answers[antenna] = tag.answers[@metric_name][:average][antenna] || @mi_class.default_value}
    answers
  end

  def tag_answers(tag)
    (1..16).map{|antenna| tag.answers[@metric_name][:average][antenna] || @mi_class.default_value}
  end

end