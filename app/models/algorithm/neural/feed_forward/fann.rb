class Algorithm::Neural::FeedForward::Fann < Algorithm::Neural
  def train_network
    input_vector = []
    output_vector = []
    @tags_for_training.values.each do |tag|
      input_vector.push add_empty_values_to_vector(tag)
      output_vector.push tag.position.to_a.map{|coord| coord.to_f / WorkZone::WIDTH}
    end

    train = RubyFann::TrainData.new(
        :inputs => input_vector,
        :desired_outputs => output_vector)
    fann = RubyFann::Standard.new(:num_inputs => 16, :hidden_neurons => [16], :num_outputs => 2)

    max_epochs = 50_000
    desired_mse = 0.001
    epochs_log_step = 500
    fann.train_on_data(train, max_epochs, epochs_log_step, desired_mse)
    fann
  end

  def make_estimate(network, tag)
    tag_data = add_empty_values_to_vector(tag)
    tag_estimate_as_a = network.run( tag_data )
    Point.from_a( tag_estimate_as_a.map{|c|c * WorkZone::WIDTH} )
  end
end