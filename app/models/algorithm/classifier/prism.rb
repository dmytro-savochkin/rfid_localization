class Algorithm::Classifier::Prism < Algorithm::Classifier

  private

  def save_in_file_by_external_mechanism
    false
  end

  def model_run_method(model, tag)
    data = tag_answers(tag)
    model.eval data
  end


  def train_model(tags_train_input, height)
    train = []
    tags_train_input.values.each do |tag|
      nearest_antenna_number = tag.nearest_antenna.number
      train.push(tag_answers(tag) + [nearest_antenna_number])
    end

    data_set = MyDataSet.new(:data_items=>train, :data_labels=> (1..17).to_a.map(&:to_s))
    MyPrism.new.build(data_set)
  end
end


class MyPrism < Ai4r::Classifiers::Prism
  def build(data_set)
    data_set.clear_for_ambiguity
    data_set.check_data_ambiguity
    super
  end
end

class MyDataSet < Ai4r::Data::DataSet
  def clear_for_ambiguity
    items = []
    @data_items.each_with_index do |datum, i|
      input = datum[0..-2].to_s
      if items.include? input
        @data_items.delete datum
      else
        items.push input
      end
    end
  end

  def check_data_ambiguity
    items_hash = {}
    @data_items.each do |datum|
      input = datum[0..-2]
      output = datum.last
      if items_hash[input.to_s].nil?
        items_hash[input.to_s] = output.to_s
      else
        raise ArgumentError, "Ambiguous data." if items_hash[input.to_s] != output.to_s
      end
    end
  end
end
