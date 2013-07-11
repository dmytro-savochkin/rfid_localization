class Algorithm::Classifier::Classifier < Algorithm::Base

  attr_reader :tags_for_table

  def set_settings(metric_name = :rss, tags_for_table)
    @metric_name = metric_name
    @mi_class = MeasurementInformation::Base.class_by_mi_type(metric_name)
    @tags_for_table = tags_for_table
    self
  end



  private


  def calculate_tags_output
    tags_estimates = {}

    model = train_model

    @tags.each do |tag_index, tag|
      zone_estimate = model_run_method(model, tag)

      puts zone_estimate.to_s
      zone = Zone.new(zone_estimate)
      puts zone.coordinates.nil?
      if zone.coordinates.nil?
        tag_output = TagOutput.new(tag, Point.new(nil,nil), zone)
      else
        tag_output = TagOutput.new(tag, zone.coordinates, zone)
      end
      tags_estimates[tag_index] = tag_output
    end

    tags_estimates
  end


  def tag_answers(tag)
    (1..16).map{|antenna| tag.answers[@metric_name][:average][antenna] || @mi_class.default_value}
  end

end