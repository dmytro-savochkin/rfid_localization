class MI::Rss < MI::Base
  MINIMAL_POSSIBLE_MI_VALUE = -700.5

  def initialize(rss, reader_power)
    @rss = rss
    @reader_power = reader_power
  end

  def self.to_distance(rss, angle, antenna, antenna_type, height, reader_power, model_type, ellipse_ratio)
    db_antenna = antenna
    db_antenna = 'all' if antenna_type == :average

    cache_name = 'rss_to_distance_' + height.to_s + reader_power.to_s + 'one' + db_antenna.to_s + model_type.to_s

    model = Rails.cache.fetch(cache_name, :expires_in => 2.day) do
      Regression::RegressionModel.where({
          :height => height,
          :reader_power => reader_power,
          :antenna_number => db_antenna,
          :mi_type => 'rss',
          :type => model_type
      }).first
    end


    if model_type == 'new_elliptical_watt' or model_type == 'new_circular_watt'
      rss = to_watt(rss)
    else
      rss = rss.abs
    end


    if model_type == 'new_elliptical' or model_type == 'new_elliptical_watt'
      #puts 'ellipse'
      distance = (
          model.const.to_f +
          model.mi_coeff.to_f * rss +
          model.mi_coeff_t.to_f * ( rss ** 2 ) +
          model.angle_coeff.to_f * rss * ellipse(angle, ellipse_ratio) +
          model.angle_coeff_t.to_f * ( rss ** 2 ) * ellipse(angle, ellipse_ratio)
      )
    elsif model_type == 'new_circular' or model_type == 'new_circular_watt'
      #puts 'circular'
      distance = (
          model.const.to_f +
          model.mi_coeff.to_f * rss +
          model.mi_coeff_t.to_f * ( rss ** 2 )
      )
    else
      #puts 'old'
      distance = (
          model.const.to_f +
          model.mi_coeff.to_f * rss +
          model.angle_coeff.to_f * rss * Math.cos(angle)
      )
    end


    #distance1 = (
    #    model.const.to_f +
    #    model.mi_coeff.to_f * rss +
    #    model.mi_coeff_t.to_f * ( rss ** 2 ) +
    #    model.angle_coeff.to_f * rss * ellipse(angle, ellipse_ratio) +
    #    model.angle_coeff_t.to_f * ( rss ** 2 ) * ellipse(angle, ellipse_ratio)
    #)
    #distance2 = (
    #    model.const.to_f +
    #    model.mi_coeff.to_f * rss +
    #    model.angle_coeff.to_f * rss * Math.cos(angle)
    #)



    #puts rss.to_s
    #puts angle.to_s
    #puts ellipse(angle).to_s
    #puts antenna.to_s
    #puts antenna_type.to_s
    #puts height.to_s
    #puts reader_power.to_s
    #puts model_type.to_s
    #puts model.const.to_s + ' ' + model.mi_coeff.to_s + ' ' + model.mi_coeff_t.to_s + ' ' +
    #    model.angle_coeff.to_s + ' ' + model.angle_coeff_t.to_s
    #puts distance.to_s + ' - ' + 38.4239357274105.to_s
    #puts ''



    [distance, 0.0].max
  end




  def self.to_distance_old(rss)
    rss = (rss.to_f.abs - 61.0).abs
    return 0.0 if rss < 0
    rss * 5.0
  end


  def self.to_watt(dbm)
    10 ** ((dbm.to_f - 30) / 10)
  end

  def self.from_watt(rss_in_watts)
    10 * Math.log(rss_in_watts, 10) + 30
  end


  def self.default_value
    -75.0
  end

  def self.range
    [-60.0, -75.0]
  end
end