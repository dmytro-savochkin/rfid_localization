class Regression::ModelCreator
  def initialize
    @mi_type = :rss
    @model_type = :one
  end



  def create_models
    add_to_db = true

    height = MeasurementInformation::Base::HEIGHTS.first

    regression_models = {}
    ((20..24).to_a + [:sum]).each do |reader_power|
      regression_models[reader_power] ||= {}

      data_array = []
      (1..16).each do |antenna_number|
        mi_map = parse_for_antenna_mi_data(antenna_number, height, reader_power)
        data = create_regression_arrays(antenna_number, mi_map)
        data_array.push data
        regression_models[reader_power][antenna_number] = make_regression_model(data)
        save_regression_model_into_db(height, reader_power, antenna_number, regression_models, add_to_db)
      end

      regression_models[reader_power][:all] = make_regression_model(data_array)
      save_regression_model_into_db(height, reader_power, :all, regression_models, add_to_db)
    end

    regression_models
  end












  private




  def parse_for_antenna_mi_data(antenna, height, reader_power)
    mi_map = {}

    tags = MeasurementInformation::Base.parse[reader_power][height][:tags]
    tags.values.each do |tag|
      tag.answers[@mi_type][:average].each do |antenna_name, mi|
        mi_map[tag.position] = mi.abs if antenna_name == antenna
      end
    end

    mi_map
  end






  def create_regression_arrays(antenna_number, mi_map)
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
        :angles => angles_values
    }
  end





  def make_regression_model(data)
    if data.class == Array
      mi = data.map{|vd| vd[:mi]}.flatten.to_vector(:scale)
      mi_transformed = data.map{|vd| self.send(@model_type, vd[:mi])  }.flatten.to_vector(:scale)
      angles = data.map{|vd|vd[:angles]}.flatten.map.with_index { |x, i| Math.cos(x) * mi[i] }.to_vector(:scale)
      distances = data.map{|vd|vd[:distances]}.flatten.to_vector(:scale)
    else
      mi = data[:mi].to_vector(:scale)
      mi_transformed = self.send(@model_type, data[:mi]).to_vector(:scale)
      angles = data[:angles].map.with_index { |x, i| Math.cos(x) * mi[i] }.to_vector(:scale)
      distances = data[:distances].to_vector(:scale)
    end


    ds = {
        'a_mi' => mi_transformed,
        'b_angle' => angles,
        'y' => distances
    }.to_dataset
    mlr = Statsample::Regression.multiple(ds, 'y')




    errors_with_regression = distances.map.with_index do |distance, i|
      regression_distance = (mlr.constant + mi_transformed[i] * mlr.coeffs['a_mi'] + mlr.coeffs['b_angle'] * Math.cos(angles[i]) * mi[i])
      ( distance - regression_distance ).abs
    end
    errors_without_regression = mi.map.with_index do |mi,i|
      (distances[i] - mi_class.to_distance_old(mi)).abs
    end

    {
        :const => mlr.constant,
        :mi_coeff => mlr.coeffs['a_mi'],
        :angle_coeff => mlr.coeffs['b_angle'],
        :errors_with_regression => errors_with_regression.mean,
        :errors_without_regression => errors_without_regression.mean
    }
  end









  def one(x)
    x
  end
  def square(x)
    x.map{|v| v ** 2}
  end
  def root(x)
    x.map{|v| Math.sqrt(v)}
  end








  def mi_class
    ('MeasurementInformation::' + @mi_type.to_s.capitalize).constantize
  end


  def save_regression_model_into_db(height, reader_power, antenna_number, models, add = false)
    not_found = Regression::RegressionModel.where(:height => height,
                                              :reader_power => reader_power,
                                              :antenna_number => antenna_number.to_s,
                                              :type => @model_type,
                                              :mi_type => @mi_type).count == 0

    if not_found and add
      model = Regression::RegressionModel.new(
          {
              :mi_type => @mi_type,
              :type => @model_type,
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

end