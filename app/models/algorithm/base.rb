class Algorithm::Base

  def initialize(input, train_data)
    @work_zone = input[:work_zone]
    @reader_power = input[:reader_power]
    @tags_input = train_data
  end

  def set_settings(metric_name = :rss)
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


  #def get_train_and_test_heights
  #  if @heights_combinations == :all
  #    train_heights = (0..3)
  #    test_heights = (0..3)
  #  elsif @heights_combinations == :basic
  #    train_heights = [3]
  #    test_heights = (0..3)
  #  else
  #    train_heights = [3]
  #    test_heights = [0]
  #  end
  #  [train_heights, test_heights]
  #end




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