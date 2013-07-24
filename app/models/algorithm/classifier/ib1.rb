class Algorithm::Classifier::Ib1 < Algorithm::Classifier::Classifier

  private

  def model_run_method(model, tag)
    data = tag_answers(tag)
    model.eval data
  end


  def train_model
    train = []
    @tags_for_table.values.each do |tag|
      nearest_antenna_number = tag.nearest_antenna.number
      train.push(tag_answers(tag) + [nearest_antenna_number])
    end

    data_set = Ai4r::Data::DataSet.new(:data_items=>train, :data_labels=> (1..17).to_a)
    Ai4r::Classifiers::IB1.new.build(data_set)
  end
end