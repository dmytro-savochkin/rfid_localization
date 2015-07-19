class Algorithm::Base

  attr_reader :tags_input, :reader_power, :work_zone, :heights_combinations, :setup,
              :model_must_be_retrained


  def initialize(reader_power, manager_id, train_data, model_must_be_retrained, antennae = WorkZone.create_default_antennae(16, 70, [250,160], [300,190], Math::PI/4, :grid))
    @reader_power = reader_power
    @manager_id = manager_id
		@work_zone = WorkZone.new(antennae, reader_power)
    @tags_input = train_data
    @model_must_be_retrained = model_must_be_retrained
  end

  def set_settings(mi_model_type, metric_name = :rss)
		@mi_model_type = mi_model_type
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
      model = train_model(train_data, @heights_combinations[index][:train], create_model_id(index))
			@setup[index] = set_up_model(model, train_data, setup_data, index)

      if @setup[index].is_a? Hash and @setup[index][:retrained_model].present?
        model = @setup[index][:retrained_model]
      end

      specific_output(model, test_data, index)
		end

    self
  end







  private

  def create_model_id(height_index)
    @manager_id.to_s + '__' + @heights_combinations[height_index][:train].to_s
  end


  def retrain_model(train_data, setup_data, heights)
    if @model_must_be_retrained
      full_data = train_data.dup
      setup_data.each do |tag_index, tag|
        full_data[tag_index + '_s'] = tag.dup
      end
      heights_unique_id = @manager_id.to_s + '_' + heights[:train].to_s + '_' + heights[:setup].to_s
      return train_model(full_data, heights[:train], heights_unique_id)
    end
    nil
  end





  def tag_answers_empty_hash
    answers = {}
		@work_zone.antennae.keys.each{|antenna| answers[antenna] = (@mi_default || @mi_class.default_value)}
    answers
  end

  def tag_answers_hash(tag)
    answers = {}
		@work_zone.antennae.keys.each{|antenna| answers[antenna] = tag.answers[@metric_name][:average][antenna] || @mi_default || @mi_class.default_value}
    answers
  end

  def tag_answers(tag)
		@work_zone.antennae.keys.map do |antenna|
      tag.answers[@metric_name][:average][antenna] || @mi_default || @mi_class.default_value
    end
  end

  def normalized_tag_answers(tag, reader_power = 23)
		if @metric_name == :rss
			range = (@mi_model_type == :theoretical ? MI::Rss.theoretical_range(reader_power) : nil)
			tag_answers(tag).map{|value| @mi_class.normalize_value(value, reader_power, range)}
		else
			tag_answers(tag).map{|value| @mi_class.normalize_value(value, reader_power)}
		end
  end
end