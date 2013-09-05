class Algorithm::PointBased::Neural::FeedForward::FannTotal < Algorithm::PointBased::Neural
  def set_settings(tags_for_training)
    @mi_classes = {
        :rss => MI::Rss,
        :rr => MI::Rr,
    }
    @tags_for_table = tags_for_training
    self
  end


  def train_network(hidden_neurons_count = 16)
    input_vector = []
    output_vector = []
    @tags_for_table.values.each do |tag|
      rss_vector = add_empty_values_to_vector(tag, :rss)
      rr_vector = add_empty_values_to_vector(tag, :rr)
      input_vector.push(rss_vector + rr_vector)
      output_vector.push(tag.position.to_a.map{|coord| coord.to_f / WorkZone::WIDTH})
    end

    train = RubyFann::TrainData.new(
        :inputs => input_vector,
        :desired_outputs => output_vector)
    fann = RubyFann::Standard.new(:num_inputs => 32, :hidden_neurons => [hidden_neurons_count], :num_outputs => 2)

    max_epochs = 50_000
    desired_mse = 0.001
    epochs_log_step = 500
    fann.train_on_data(train, max_epochs, epochs_log_step, desired_mse)
    fann
  end

  def make_estimate(network, tag)
    rss_data = add_empty_values_to_vector(tag, :rss)
    rr_data = add_empty_values_to_vector(tag, :rr)
    tag_estimate_as_a = network.run( rss_data + rr_data )
    Point.from_a( tag_estimate_as_a.map{|c|c * WorkZone::WIDTH} )
  end


end