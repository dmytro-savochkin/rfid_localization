class Algorithm::PointBased::Neural < Algorithm::PointBased

  def set_settings(metric_name, hidden_neurons_count)
    @metric_name = metric_name
    @mi_class = MI::Base.class_by_mi_type(metric_name)
    @hidden_neurons_count = hidden_neurons_count
    self
  end



  private


  def train_model(tags_train_input, height)
    fann_class = Algorithm::PointBased::Neural::Fann
    nn_file = get_nn_file(height)
    return fann_class.new(:filename => nn_file) if nn_file.present?

    input_vector = []
    output_vector = []
    tags_train_input.values.each do |tag|
      input_vector.push normalize_data(tag_answers(tag))
      output_vector.push tag.position.to_a.map{|coord| coord.to_f / WorkZone::WIDTH }
    end

    train = RubyFann::TrainData.new(
        :inputs => input_vector,
        :desired_outputs => output_vector)
    fann = fann_class.new(:num_inputs => 16, :hidden_neurons => [@hidden_neurons_count], :num_outputs => 2)
    fann.algorithm = self
    fann.train_input = tags_train_input

    max_epochs = 50_000
    desired_mse = 0.00001
    epochs_log_step = 500
    fann.train_on_data(train, max_epochs, epochs_log_step, desired_mse)
    fann.save(nn_file_dir + @reader_power.to_s + '_'  + @metric_name.to_s + '_' + height.to_s + '_' + fann.error_sum.round.to_s + '.nn')
    fann
  end

  def model_run_method(network, setup, tag)
    #puts tag.id.to_s
    #puts tag_answers(tag).to_s
    #puts normalize_data(tag_answers(tag)).to_s
    #puts ''

    tag_data = normalize_data(tag_answers(tag))
    tag_estimate_as_a = network.run( tag_data )
    Point.from_a( tag_estimate_as_a.map{|c|c * WorkZone::WIDTH} )
  end






  def normalize_data(data)
    data.map{|datum| normalize_datum(datum)}
  end

  def normalize_datum(datum)
    return datum if @metric_name == :rr
    range = @mi_class.range
    (range[1].abs - datum.abs) / (range[1].abs - range[0].abs)
  end



  def nn_file_dir
    Rails.root.to_s + '/app/models/algorithm/point_based/models/neural/'
  end
  def nn_file_mask(height)
    @reader_power.to_s + '_' + @metric_name.to_s + '_' + height.to_s + '_[\d]+.nn'
  end
  def get_nn_file(height)
    file_reg_exp = Regexp.new(nn_file_mask(height))
    files = Dir.entries(nn_file_dir).select do |f|
      good = File.file?(nn_file_dir.to_s + f.to_s) && file_reg_exp.match(f)
      good
    end
    return nil if files.first.nil?
    nn_file_dir.to_s + files.first
  end
end