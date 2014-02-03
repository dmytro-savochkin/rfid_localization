class Algorithm::Classifier::Hyperpipes < Algorithm::Classifier

  private

  def model_run_method(model, setup, tag)
    data = tag_answers(tag)
    probabilities = model.eval(data)

    {
        :probabilities => probabilities,
        :result_zone => probabilities.key(probabilities.values.max).to_i
    }
  end


  def train_model(tags_train_input, height, model_id)
    train = []
    tags_train_input.values.each do |tag|
      nearest_antenna_number = tag.nearest_antenna.number
      mi_answers = (1..16).map{|antenna| tag.answers[@metric_name][:average][antenna] || @mi_class.default_value}
      train.push(mi_answers + [nearest_antenna_number.to_s])
    end

    data_set = Ai4r::Data::DataSet.new(:data_items=>train, :data_labels=> (1..17).to_a.map(&:to_s))
    ProbabilisticHyperpipes.new.build(data_set)
  end
end



class ProbabilisticHyperpipes < Ai4r::Classifiers::Hyperpipes
  def eval(data)
    votes = Hash.new {0}
    @pipes.each do |category, pipe|
      pipe.each_with_index do |bounds, i|
        if data[i].is_a? Numeric
          votes[category] += 1 if data[i] >= bounds[:min] && data[i] <= bounds[:max]
        else
          votes[category] += 1 if bounds[data[i]]
        end
      end
    end

    max_votes = votes.values.max.to_f
    probabilities = {}
    votes.sort_by{|k,v|k.to_i}.each do |category, votes_count|
      zone_number = category.to_i
      probabilities[zone_number] = votes_count.to_f / max_votes
    end

    probabilities
  end
end