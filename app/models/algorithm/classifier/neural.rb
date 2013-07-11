class Algorithm::Classifier::Neural < Algorithm::Classifier::Classifier

  private

  def model_run_method(network, tag)
    data = add_empty_values_to_vector(tag)
    antennae = network.run( data )
    antennae.index(antennae.max) + 1
  end



  def train_model
    fann_class = Algorithm::Classifier::Neural::FannWithDistancesTraining
    nn_file = get_nn_file
    return fann_class.new(:filename => nn_file) if nn_file.present?

    input_vector = []
    output_vector = []

    empty_array = [0] * 16

    @tags_for_table.values.each do |tag|
      input_vector.push add_empty_values_to_vector(tag)
      output = empty_array.dup
      output[tag.nearest_antenna.number - 1] = 1.0
      output_vector.push output
    end

    train = RubyFann::TrainData.new(
        :inputs => input_vector,
        :desired_outputs => output_vector)
    fann = fann_class.new(:num_inputs => 16, :hidden_neurons => [16], :num_outputs => 16)
    fann.algorithm = self

    max_epochs = 10_000
    desired_mse = 0.001
    epochs_log_step = 1
    fann.train_on_data(train, max_epochs, epochs_log_step, desired_mse)
    fann.save(nn_file_dir + @reader_power.to_s + '_'  + @metric_name.to_s + '_' + fann.error_sum.round.to_s + '.nn')
    fann
  end











  def add_empty_values_to_vector(tag_answers)
    filled_answers = []
    (1..16).each do |antenna|
      datum = tag_answers.answers[@metric_name][:average][antenna] || @mi_class.default_value
      filled_answers.push normalize_datum(datum)
    end
    filled_answers
  end

  def normalize_datum(datum)
    return datum if @metric_name == :rr
    range = @mi_class.abs_range
    (range[1] - datum.abs) / (range[1] - range[0])
  end











  def nn_file_dir
    Rails.root.to_s + '/app/models/algorithm/classifier/neural/'
  end
  def nn_file_mask
    @reader_power.to_s + '_' + @metric_name.to_s + '_[\d]+.nn'
  end
  def get_nn_file
    file_reg_exp = Regexp.new(nn_file_mask)
    files = Dir.entries(nn_file_dir).select do |f|
      good = File.file?(nn_file_dir.to_s + f.to_s) && file_reg_exp.match(f)
      good
    end
    return nil if files.first.nil?
    nn_file_dir.to_s + files.first
  end
end