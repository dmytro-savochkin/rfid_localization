class Regression::ModelCreator
  def initialize
    @data_file_name = Rails.root.to_s + "/app/raw_input/rfid exp results 31.07  multi.xls"
    @mi_type = :rr
    @mi_class = MeasurementInformation::Rr
  end



  def create_models
    reader_powers = MeasurementInformation::Base::READER_POWERS
    heights = MeasurementInformation::Base::HEIGHTS

    height = 41




    models = {}
    (20..24).each do |reader_power|
      models[reader_power] ||= {}

      data_array = []
      errors = []
      errors2 = []
      (1..16).each do |antenna_number|
        mi_map = parse_for_antenna(antenna_number, height, reader_power)
        data = create_data_for_antenna(antenna_number, mi_map)
        data_array.push data
        models[reader_power][antenna_number] = regression(data)

        save_regression_model_into_db(height, reader_power, antenna_number, models)

        errors.push models[reader_power][antenna_number][:error]
        errors2.push models[reader_power][antenna_number][:error2]
      end

      consts = models[reader_power].values.map{|d|d[:const]}
      as = models[reader_power].values.map{|d|d[:mi_coeff]}
      bs = models[reader_power].values.map{|d|d[:angle_coeff]}
      models[reader_power][:consts] = consts
      models[reader_power][:as] = as
      models[reader_power][:bs] = bs

      models[reader_power][:all_error] = errors.mean
      models[reader_power][:all_error2] = errors2.mean

      models[reader_power][:all] = regression(data_array)

      save_regression_model_into_db(height, reader_power, :all, models)
    end

    models
  end









  private


  def save_regression_model_into_db(height, reader_power, antenna_number, models)
    type = 'square'

    if Regression::RegressionModel.where(:height => height,
                                         :reader_power => reader_power,
                                         :antenna_number => antenna_number.to_s,
                                         :type => type,
                                         :mi_type => @mi_type).count == 0
      model = Regression::RegressionModel.new(
          {
              :mi_type => @mi_type,
              :type => type,
              :height => height,
              :reader_power => reader_power,
              :antenna_number => antenna_number.to_s,
              :const => models[reader_power][antenna_number][:const],
              :mi_coeff => models[reader_power][antenna_number][:mi_coeff],
              :angle_coeff => models[reader_power][antenna_number][:angle_coeff]
          }
      )
      model.save
    end
  end




  def parse_for_antenna(antenna, height, reader_power)
    mi_map = {}

    tags = MeasurementInformation::Base.parse[reader_power][height][:tags]
    tags.values.each do |tag|
      tag.answers[@mi_type][:average].each do |antenna_name, mi|
        mi_map[tag.position] = mi.abs if antenna_name == antenna
      end
    end

    mi_map
  end










  def create_data_for_antenna(antenna_number, mi_map)
    antenna = Antenna.new(antenna_number)

    distances_values = []
    angles_values = []
    mi_values = []


    mi_map.each do |tag_position, mi|
      if mi != 0.0
        distances_values.push tag_position.distance_to_point(antenna.coordinates)
        angles_values.push antenna.coordinates.angle_to_point(tag_position)
        mi_values.push mi
      end
    end

    {
        :distances => distances_values,
        :mi => mi_values,
        :mi_squares => mi_values.map{|mi|mi ** 2},
        :mi_sqrts => mi_values.map{|mi|Math.sqrt(mi)},
        :angles => angles_values
    }
  end









  def regression(data)
    if data.class == Array
      mi = data.map{|vd|vd[:mi]}.flatten.to_vector(:scale)
      angles = data.map{|vd|vd[:angles]}.flatten.map.with_index { |x, i| Math.cos(x) * mi[i] }.to_vector(:scale)
      distances = data.map{|vd|vd[:distances]}.flatten.to_vector(:scale)
      mi_squares = data.map{|vd|vd[:mi_squares]}.flatten.to_vector(:scale)
      mi_sqrts = data.map{|vd|vd[:mi_sqrts]}.flatten.to_vector(:scale)
    else
      mi = data[:mi].to_vector(:scale)
      angles = data[:angles].map.with_index { |x, i| Math.cos(x) * mi[i] }.to_vector(:scale)
      distances = data[:distances].to_vector(:scale)
      mi_squares = data[:mi_squares].to_vector(:scale)
      mi_sqrts = data[:mi_sqrts].to_vector(:scale)
    end


    ds = {
        'a_mi' => mi,
        'b_angle' => angles,
        'y' => distances
    }.to_dataset
    mlr = Statsample::Regression.multiple(ds, 'y')




    errors = distances.map.with_index do |distance, i|
      regression_distance = (mlr.constant + mi[i] * mlr.coeffs['a_mi'] + mlr.coeffs['b_angle'] * Math.cos(angles[i]) * mi[i])
      ( distance - regression_distance ).abs
    end
    errors2 = mi.map.with_index do |mi,i|
      (distances[i] - @mi_class.to_distance_old(mi)).abs
    end

    {
        :const => mlr.constant,
        :mi_coeff => mlr.coeffs['a_mi'],
        :angle_coeff => mlr.coeffs['b_angle'],
        :error => errors.mean,
        :error2 => errors2.mean
    }
  end

end