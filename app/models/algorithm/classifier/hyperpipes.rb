class Algorithm::Classifier::Hyperpipes < Algorithm::Classifier

  private

  def model_run_method(model, tag)
    data = tag_answers(tag)
    model.eval data
  end


  def train_model(tags_train_input)
    train = []
    tags_train_input.values.each do |tag|
      nearest_antenna_number = tag.nearest_antenna.number
      mi_answers = (1..16).map{|antenna| tag.answers[@metric_name][:average][antenna] || @mi_class.default_value}
      train.push(mi_answers + [nearest_antenna_number.to_s])
    end

    data_set = Ai4r::Data::DataSet.new(:data_items=>train, :data_labels=> (1..17).to_a.map(&:to_s))
    Ai4r::Classifiers::Hyperpipes.new.build(data_set)
  end
end