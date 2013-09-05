#
## WRONG WORK HERE
#
#
#class Algorithm::Neural::Recurrent::Tlearn < Algorithm::Neural
#
#  def set_settings(tags_for_training)
#    @mi_classes = {
#        :rss => MI::Rss,
#        :rr => MI::Rr,
#    }
#    @tags_for_training = tags_for_training
#    self
#  end
#
#
#  def train_network
#    tlearn = TLearn::Run.new(:number_of_nodes => 16+16+2,
#                             :'output_nodes'    => 17..18,
#                             :linear          => 19..34,
#                             :weight_limit    => 1.00,
#                             :connections     => [
#                                 {1..18   => 0},
#                                 {1..16   => :i1..:i16},
#                                 {1..16  => 19..34},
#                                 {17..18   => 1..16},
#                                 {19..34  => [1..16, {:min => 1.0, :max => 1.0}, :fixed, :'one_to_one']}
#                             ])
#
#    training_data = []
#    @tags_for_training.values.each do |tag|
#      rss_input = add_empty_values_to_vector(tag, :rss)
#      rr_input = add_empty_values_to_vector(tag, :rr)
#      output = tag.position.to_a.map{|coord| coord.to_f / WorkZone::WIDTH}
#
#
#
#      training_data.push( [{rss_input => output}, {rr_input => output}] )
#    end
#
#    puts training_data.to_yaml
#
#    tlearn.train(training_data, 5000, '/users/Sevlord/rails/rfid/app/raw_output')
#    tlearn
#  end
#
#
#
#
#  def make_estimate(network, tag)
#    rss_data = add_empty_values_to_vector(tag, :rss)
#    rr_data = add_empty_values_to_vector(tag, :rr)
#    rss = network.fitness(rss_data, sweeps = 1, '/users/Sevlord/rails/rfid/app/raw_output')
#    rss
#  end
#end