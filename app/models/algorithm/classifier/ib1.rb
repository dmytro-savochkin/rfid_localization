class Algorithm::Classifier::Ib1 < Algorithm::Classifier

  private

  def model_run_method(model, setup, tag)
    data = tag_answers(tag)
    {
        :probabilities => {},
        :result_zone => model.eval(data)
    }
  end


  def train_model(tags_train_input, height, model_id)
    train = []
    tags_train_input.values.each do |tag|
      nearest_antenna_number = tag.nearest_antenna.number
      train.push(tag_answers(tag) + [nearest_antenna_number])
    end

    data_set = Ai4r::Data::DataSet.new(:data_items => train, :data_labels => (1..17).to_a)
    Ai4r::Classifiers::IB1.new.build(data_set)
  end
end


#class Ai4r::Classifiers::IB1
#  def eval_with_probability(data)
#    update_min_max(data)
#    size = @data_set.data_items.length - 1
#    min_distances = [1.0/0] * size
#    klasses = {}
#
#    @data_set.data_items.each do |train_item|
#      train_item_class = train_item.last - 1
#      d = distance(data, train_item)
#      if d < klasses[train_item_class]
#        klasses[train_item_class] = d
#      end
#    end
#    klasses
#  end
#end