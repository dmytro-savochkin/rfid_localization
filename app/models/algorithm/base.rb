class Algorithm::Base

  attr_reader :tags_input, :reader_power, :work_zone, :heights_combinations, :setup,
              :model_must_be_retrained


  def initialize(reader_power, train_data, model_must_be_retrained)
    @reader_power = reader_power
    @work_zone = WorkZone.new(reader_power)
    @tags_input = train_data
    @model_must_be_retrained = model_must_be_retrained
  end

  def set_settings(metric_name = :rss)
    @metric_name = metric_name
    @mi_class = MI::Base.class_by_mi_type(metric_name)
    self
  end





  def output()
    @setup = {}
    @map = {}
    @heights_combinations = {}

    @tags_input.each_with_index do |tags_input_current_height, index|
      train_data = tags_input_current_height[:train]
      setup_data = tags_input_current_height[:setup]
      test_data = tags_input_current_height[:test]

      @heights_combinations[index] = tags_input_current_height[:heights]

      model = train_model(train_data, @heights_combinations[index][:train])
      @setup[index] = set_up_model(model, train_data, setup_data, index)


      #puts model[:data].length.to_s
      if @setup[index].is_a? Hash and @setup[index][:retrained_model].present?
        #puts @setup[index][:retrained_model].to_yaml
        model = @setup[index][:retrained_model]
      end
      #puts model[:data].length.to_s


      specific_output(model, test_data, index)
    end

    self
  end







  private

  def retrain_model(train_data, setup_data, heights)
    if @model_must_be_retrained
      full_data = train_data.dup
      setup_data.each do |tag_index, tag|
        full_data[tag_index + '_s'] = tag.dup
      end
      return train_model(full_data, heights)
    end
    nil
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