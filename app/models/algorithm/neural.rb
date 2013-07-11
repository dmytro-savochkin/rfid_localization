class Algorithm::Neural < Algorithm::Base

  def set_settings(metric_name, tags_for_training)
    @metric_name = metric_name
    @mi_classes = {
      :rss => MeasurementInformation::Rss,
      :rr => MeasurementInformation::Rr,
    }
    @tags_for_training = tags_for_training
    self
  end



  private


  def calculate_tags_output
    tags_estimates = {}

    trained_network = train_network

    @tags.each do |tag_index, tag|
      tag_estimate = make_estimate(trained_network, tag)
      tag_output = TagOutput.new(tag, tag_estimate)
      tags_estimates[tag_index] = tag_output
    end

    tags_estimates
  end




  def train_network
    raise Exception.new("must use children's classes")
  end



  def add_empty_values_to_vector(tag_answers, metric_name = @metric_name)
    filled_answers = []
    (1..16).each do |antenna|
      datum = tag_answers.answers[metric_name][:average][antenna] || @mi_classes[metric_name].default_value
      filled_answers.push normalize_datum(datum, metric_name)
    end
    filled_answers
  end

  def normalize_datum(datum, metric_name)
    return datum if @metric_name == :rr
    range = @mi_classes[metric_name].abs_range
    (range[1] - datum.abs) / (range[1] - range[0])
  end
end