class Algorithm::Classifier::Neural < Algorithm::Classifier

  private

  def model_run_method(network, setup, tag)
    data = normalized_tag_answers(tag)
    antennae = network.run( data )

    probabilities = {}
    antennae.each_with_index{|confidence, i| probabilities[i + 1] = confidence}

    {
        :probabilities => probabilities,
        :result_zone => antennae.index(antennae.max) + 1
    }
  end



  def train_model(tags_train_input, height, model_id)
    model_id = model_id.to_s.gsub(/[^\d\w,_]/, '')
    fann_class = FannWithDistancesTraining
    nn_file = get_model_file(model_id)
    return fann_class.new(:filename => nn_file) if nn_file.present?

    input_vector = []
    output_vector = []

    empty_array = [0] * 16

    tags_train_input.values.each do |tag|
      input_vector.push normalized_tag_answers(tag)
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
    epochs_log_step = 50
    fann.train_on_data(train, max_epochs, epochs_log_step, desired_mse)
    if fann.accuracy > fann.class::ACCEPTED_ACCURACY
      fann.save(model_file_dir + model_file_prefix(model_id) + '_' + fann.accuracy.round(2).to_s)
    end
    fann.algorithm = nil
    fann
  end




  def model_file_dir
    Rails.root.to_s + '/app/models/algorithm/classifier/models/neural/'
  end
end




class FannWithDistancesTraining < RubyFann::Standard
  attr_reader :accuracy
  attr_accessor :algorithm, :train_input

  ACCEPTED_ACCURACY = 0.91 unless const_defined?(:ACCEPTED_ACCURACY)

  def training_callback(args)
    @accuracy = 0.0
    @train_input.values.each do |tag|
      zone_estimate = @algorithm.send(:model_run_method, self, nil, tag)[:result_zone]
      @accuracy += 1.0 if tag.zone.to_i == zone_estimate.to_i
    end
    @accuracy /= @train_input.length

    puts @accuracy.to_s

    #accepted_accuracy = 0.95
    #accepted_accuracy = 0.92 if @algorithm.reader_power >= 22
    #accepted_accuracy = 0.9 if @algorithm.reader_power >= 24

    if @accuracy > ACCEPTED_ACCURACY
      return -1
    end
    0
  end
end