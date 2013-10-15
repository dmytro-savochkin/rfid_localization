class Algorithm::Classifier::Neural < Algorithm::Classifier

  private

  def save_in_file_by_external_mechanism
    false
  end


  def model_run_method(network, tag)
    data = add_empty_values_to_vector(tag)
    antennae = network.run( data )

    probabilities = {}
    antennae.each_with_index{|confidence, i| probabilities[i + 1] = confidence}

    {
        :probabilities => probabilities,
        :result_zone => antennae.index(antennae.max) + 1
    }
  end



  def train_model(tags_train_input, height)
    fann_class = FannWithDistancesTraining
    nn_file = get_nn_file(height)
    return fann_class.new(:filename => nn_file) if nn_file.present?

    input_vector = []
    output_vector = []

    empty_array = [0] * 16

    tags_train_input.values.each do |tag|
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
    fann.train_input = tags_train_input

    max_epochs = 10_000
    desired_mse = 0.001
    epochs_log_step = 1
    fann.train_on_data(train, max_epochs, epochs_log_step, desired_mse)
    fann.save(nn_file_dir + @reader_power.to_s + '_' + height.to_s + '_' + @metric_name.to_s + '_' + fann.accuracy.round(2).to_s + '.nn')
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
    range = @mi_class.range
    (range[1].abs - datum.abs) / (range[1].abs - range[0].abs)
  end



  def nn_file_dir
    Rails.root.to_s + '/app/models/algorithm/classifier/models/neural/'
  end
  def nn_file_mask(height)
    @reader_power.to_s + '_' + height.to_s + '_' + @metric_name.to_s + '_[\d\.]+.nn'
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




class FannWithDistancesTraining < RubyFann::Standard
  attr_reader :accuracy
  attr_accessor :algorithm, :train_input

  def training_callback(args)
    @accuracy = 0.0
    @train_input.values.each do |tag|
      zone_estimate = @algorithm.send(:model_run_method, self, tag)
      @accuracy += 1.0 if tag.zone == zone_estimate
    end
    @accuracy /= @train_input.length

    puts @accuracy.to_s

    accepted_accuracy = 0.94
    accepted_accuracy = 0.92 if @algorithm.reader_power >= 22
    accepted_accuracy = 0.9 if @algorithm.reader_power >= 24

    if @accuracy > accepted_accuracy
      return -1
    end
    0
  end
end