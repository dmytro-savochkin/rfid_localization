class Algorithm::Classifier::Id3 < Algorithm::Classifier

  private

  def model_run_method(model, tag)
    begin
      data = tag_answers(tag)
      model.eval data
    rescue Ai4r::Classifiers::ModelFailureError => e
      nil
    end
  end


  def train_model(tags_train_input)
    train = []
    tags_train_input.values.each do |tag|
      nearest_antenna_number = tag.nearest_antenna.number
      train.push(tag_answers(tag) + [nearest_antenna_number])
    end

    data_set = Ai4r::Data::DataSet.new(:data_items=>train, :data_labels=> (1..17).to_a)
    id3 = Ai4r::Classifiers::ID3.new.build(data_set)
    id3
  end
end