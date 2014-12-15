class MI::Rr < MI::Base
  MINIMAL_POSSIBLE_MI_VALUE = 0.0

  def initialize(rr, reader_power)
    @rr = rr
    @reader_power = reader_power
  end

  def self.to_distance(rr, angle, antenna, antenna_type, height, reader_power, model_type, ellipse_ratio)
    db_antenna = antenna
    db_antenna = 'all' if antenna_type == :average

    cache_name = 'rr_to_distance_' + height.to_s + reader_power.to_s +
        db_antenna.to_s + model_type.to_s


    model = Rails.cache.fetch(cache_name, :expires_in => 2.day) do
      Regression::DistancesMi.where({
          :height => height,
          :reader_power => reader_power,
          :antenna_number => db_antenna,
          :type => model_type,
          :mi_type => 'rr'
      }).first
    end


    distance = model.const.to_f

    if model_type == 'new_elliptical'

      distance += (
          model.mi_coeff.to_f * rr +
          model.mi_coeff_t.to_f * ( rr ** 2 ) +
          model.angle_coeff.to_f * rr * ellipse(angle, ellipse_ratio) +
          model.angle_coeff_t.to_f * ( rr ** 2 ) * ellipse(angle, ellipse_ratio)
      )

    else

      mi_coeffs = JSON.parse(model.mi_coeff)
      mi_coeffs.each do |mi_power, mi_coeff|
        distance += mi_coeff.to_f * (rr ** mi_power.to_f)
      end
      if ellipse_ratio != 1.0
        distance += model.angle_coeff.to_f * rr * ellipse(angle, ellipse_ratio)
      end

    end


    #if model_type == 'new_elliptical'
    #  distance = (
    #      model.const.to_f +
    #      model.mi_coeff.to_f * rr +
    #      model.mi_coeff_t.to_f * ( rr ** 2 ) +
    #      model.angle_coeff.to_f * rr * ellipse(angle) +
    #      model.angle_coeff_t.to_f * ( rr ** 2 ) * ellipse(angle)
    #  )
    #elsif model_type == 'new_circular'
    #  distance = (
    #      model.const.to_f +
    #      model.mi_coeff.to_f * rr +
    #      model.mi_coeff_t.to_f * ( rr ** 2 )
    #  )
    #else
    #  distance = (
    #      model.const.to_f +
    #      model.mi_coeff.to_f * rr +
    #      model.angle_coeff.to_f * rr * Math.cos(angle)
    #  )
    #end
    #

    [distance, 0.0].max
  end





  def self.to_distance_old(rr, angle = 1, height = 41, reader_power = 20, antenna = 1)
    rr = rr.to_f
    return 0 if rr >= 1.0
    return 100 if rr <= 0.1
    7 / rr
  end


  def self.default_value
    0.0
  end

  def self.range
    [0.0, 1.0]
  end

  def self.week_range_for_regression
    range
  end

  def self.normalize_value(datum, reader_power)
    datum
  end
end