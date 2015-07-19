class MI::Rss < MI::Base
  MINIMAL_POSSIBLE_MI_VALUE = -700.5

	GAIN = Math::db_to_linear(10.0)
	LIGHT_SPEED = 3.0 * 10 ** 8
	FREQUENCY = 915_000_000
	WAVE_LENGTH = LIGHT_SPEED / FREQUENCY
	ANTENNA_EFFECTIVE_AREA = (GAIN * WAVE_LENGTH ** 2) / (4.0 * Math::PI)
	TAG_EFFECTIVE_SCATTERING_AREA = 0.04 # 0.0018
	POLARIZATION = (2.0**0.5/2) ** 4
	#PATH_LOSS_COEFFICIENT = 0.5

	def initialize(rss, reader_power)
    @rss = rss
    @reader_power = reader_power
  end

	def self.theoretical_rss(antenna, tag_position, height_number, reader_power)
		power_out = Math::dbm_to_watt(reader_power)
		z_shift = (WorkZone::ROOM_HEIGHT - MI::Base::HEIGHTS[height_number].to_f) / 100

		xy_distance = Math.sqrt(
				(antenna.coordinates.x.to_f / 100 - tag_position.x.to_f / 100) ** 2 +
				(antenna.coordinates.y.to_f / 100 - tag_position.y.to_f / 100) ** 2
		)
		xyz_distance = Math.sqrt(xy_distance ** 2 + z_shift ** 2)

		nominator =
				POLARIZATION * power_out * GAIN * ANTENNA_EFFECTIVE_AREA *
				TAG_EFFECTIVE_SCATTERING_AREA *
				antenna_radiation_pattern(antenna, tag_position, z_shift) ** 2 *
				tag_radiation_pattern(antenna.coordinates, tag_position, z_shift) ** 2
		denominator = (4.0 * Math::PI) ** 2 * xyz_distance ** 4
		Math.watt_to_dbm(nominator / denominator)
	end


	def self.theoretical_to_distance(rss, antenna_number, height_number, reader_power, work_zone, point)
		antenna = work_zone.antennae[antenna_number]
		theoretical_to_distance_by_antenna_tag(rss, reader_power, antenna, point)
	end

	def self.theoretical_to_distance_by_antenna_tag(rss, reader_power, antenna, point)
		average_height = 60
		z_shift = (WorkZone::ROOM_HEIGHT - average_height.to_f) / 100
		nominator =
				Math::dbm_to_watt(reader_power) * POLARIZATION *
				GAIN * ANTENNA_EFFECTIVE_AREA * TAG_EFFECTIVE_SCATTERING_AREA *
				antenna_radiation_pattern(antenna, point, z_shift) ** 2 *
				tag_radiation_pattern(antenna.coordinates, point, z_shift) ** 2
		denominator = (4.0 * Math::PI) ** 2 * Math::dbm_to_watt(rss)
		full_distance = [((nominator / denominator) ** 0.25), 0.0].max
		full_distance = z_shift if full_distance < z_shift
		projection_distance = Math.sqrt(full_distance**2 - z_shift**2) * 100
		projection_distance
	end



	def self.antenna_radiation_pattern(antenna, t_c, z_shift)
		# ellipsoid semi-axes
		a = 2.0
		b = 1.0
		c = 3.0

		a_c = antenna.coordinates

		ax = a_c.x.to_f / 100
		ay = a_c.y.to_f / 100
		tx = t_c.x.to_f / 100
		ty = t_c.y.to_f / 100

		x_shift = ax - tx
		y_shift = ay - ty

		ellipsoid_in_spherical_coords = lambda do |theta, fi|
			nominator = a**2 * b**2 * c**2
			denominator =
					b**2 * c**2 * Math.cos(theta)**2 * Math.sin(fi)**2 +
					a**2 * c**2 * Math.sin(theta)**2 * Math.sin(fi)**2 +
					a**2 * b**2 * Math.cos(fi)**2
			Math.sqrt(nominator / denominator) / [a, b, c].max
		end


		fi = Math.atan2(Math.sqrt(y_shift**2 + x_shift**2), z_shift)
		if y_shift == 0.0 and x_shift == 0.0
			ellipsoid_in_spherical_coords.call(Math::PI/2, fi)
		else
			theta = Math.asin(y_shift / Math.sqrt(y_shift**2 + x_shift**2))
			if tx > ax
				ellipsoid_in_spherical_coords.call(theta + antenna.rotation, fi)
			else
				ellipsoid_in_spherical_coords.call(-theta + antenna.rotation, fi)
			end
		end
	end


	def self.tag_radiation_pattern(a_c, t_c, z_shift)
		ax = a_c.x.to_f / 100
		ay = a_c.y.to_f / 100
		tx = t_c.x.to_f / 100
		ty = t_c.y.to_f / 100

		return 1.0 if ax == tx

		x_shift = ax - tx
		y_shift = ay - ty

		k = 2.0 * Math::PI / WAVE_LENGTH
		l = 0.25 * WAVE_LENGTH
		kl = k*l

		tag_to_antenna_angle = Math.atan2(Math.sqrt(z_shift**2 + y_shift**2), x_shift.abs)

		nominator = Math.cos(kl*Math.cos(tag_to_antenna_angle) - Math.cos(kl))
		denominator = Math.sin(tag_to_antenna_angle) * (1.0 - Math.cos(kl))
		(nominator / denominator).abs
	end



	def self.to_distance(rss, angle, antenna, antenna_type, height, reader_power, model_type, ellipse_ratio)
    db_antenna = antenna
    db_antenna = 'all' if antenna_type == :average

    cache_name = 'rss_to_distance_' + height.to_s + reader_power.to_s +
        db_antenna.to_s + model_type.to_s

    model = Rails.cache.fetch(cache_name, :expires_in => 2.day) do
      Regression::DistancesMi.where({
          :height => height,
          :reader_power => reader_power,
          :antenna_number => db_antenna,
          :mi_type => 'rss',
          :type => model_type
      }).first
    end



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
    #puts ''



    if model_type.to_s.match(/watt/)
      rss = to_watt(rss)
    else
      rss = rss.abs
    end

    distance = model.const.to_f

    if model_type == 'new_elliptical' or model_type == 'new_elliptical_watt'

      distance += (
                model.mi_coeff.to_f * rss +
                model.mi_coeff_t.to_f * ( rss ** 2 ) +
                model.angle_coeff.to_f * rss * ellipse(angle, ellipse_ratio) +
                model.angle_coeff_t.to_f * ( rss ** 2 ) * ellipse(angle, ellipse_ratio)
            )

    else

      mi_coeffs = JSON.parse(model.mi_coeff)
      mi_coeffs.each do |mi_power, mi_coeff|
        distance += mi_coeff.to_f * (rss ** mi_power.to_f)
      end
      if ellipse_ratio != 1.0
        distance += model.angle_coeff.to_f * rss * ellipse(angle, ellipse_ratio)
      end

    end





    #if model_type == 'new_elliptical' or model_type == 'new_elliptical_watt'
    #  #puts 'ellipse'
    #  distance = (
    #      model.const.to_f +
    #      model.mi_coeff.to_f * rss +
    #      model.mi_coeff_t.to_f * ( rss ** 2 ) +
    #      model.angle_coeff.to_f * rss * ellipse(angle, ellipse_ratio) +
    #      model.angle_coeff_t.to_f * ( rss ** 2 ) * ellipse(angle, ellipse_ratio)
    #  )
    #elsif model_type == 'new_circular' or model_type == 'new_circular_watt'
    #  #puts 'circular'
    #  distance = (
    #      model.const.to_f +
    #      model.mi_coeff.to_f * rss +
    #      model.mi_coeff_t.to_f * ( rss ** 2 )
    #  )
    #else
    #  #puts 'old'
    #  distance = (
    #      model.const.to_f +
    #      model.mi_coeff.to_f * rss +
    #      model.angle_coeff.to_f * rss * Math.cos(angle)
    #  )
    #end


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

  def self.week_range_for_regression
    [-95.0, -48.0]
	end

	def self.theoretical_range(reader_power)
		#{max: -48.0, min: -48.0 - 0.5*reader_power.to_f + 4.0}
		{max: -36.0, min: -36.0 - 0.5*reader_power.to_f + 4.0}
	end

	def self.normalize_value(rss, reader_power, boundaries = nil)
		if boundaries.nil?
			boundaries_o = Regression::MiBoundary.where(:type => :rss, :reader_power => reader_power).first
			boundaries = {min: boundaries_o.min, max: boundaries_o.max}
		end
		max = boundaries[:max].to_f
		min = boundaries[:min].to_f
		if rss > max
			return 1.0
		end
		if rss < min
			return 0.0
		end
		(rss - min).abs / (max - min).abs
	end
end