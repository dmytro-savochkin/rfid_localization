class Algorithm::Classifier::Id3 < Algorithm::Classifier::Classifier

  private

  def model_run_method(model, tag)
    begin
      data = tag_answers(tag)
      model.eval data
    rescue Ai4r::Classifiers::ModelFailureError => e
      nil
    end
  end


  def train_model
    train = []
    @tags_for_table.values.each do |tag|
      nearest_antenna_number = tag.nearest_antenna.number
      mi_answers = (1..16).map{|antenna| tag.answers[@metric_name][:average][antenna] || @mi_class.default_value}
      train.push(mi_answers + [nearest_antenna_number])
    end

    data_set = Ai4r::Data::DataSet.new(:data_items=>train, :data_labels=> (1..17).to_a)
    id3 = Ai4r::Classifiers::ID3.new.build(data_set)
    id3
  end
end