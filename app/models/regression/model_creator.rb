class Regression::ModelCreator
  def initialize
    @mi_type = :rss
    @mi_class = ('MI::' + @mi_type.to_s.capitalize).constantize
    @add_to_db = false
    @model_type = 'const+a*x+b*x^2+c*ellipse*x+d*ellipse*x^2_a/b=1.5'
  end



  def create_models
    regression_models = {}
    errors = []

    #[1.01, 1.25, 1.5, 1.75, 2.0, 3.0, 4.0].each do |a_b_ratio|
    [2.0].each do |ellipse_ratio|
      @ellipse_ratio = ellipse_ratio
      #[1, 0.25, 0.33, 0.5, 2.0, 3.0, 4.0, 8.0, 16.0].each do |mi_power|
      [2.0].each do |mi_power|
        @mi_power = mi_power

        MI::Base::HEIGHTS.each do |height|
          regression_models[height] ||= {}
          ((20..24).to_a).each do |reader_power|
            regression_models[height][reader_power] ||= {}

            data_array = []
            (1..16).each do |antenna_number|
              mi_map = parse_for_antenna_mi_data(antenna_number, height, reader_power)
              data = create_regression_arrays(antenna_number, mi_map)
              data_array.push data.first
              regression_models[height][reader_power][antenna_number] = make_regression_model(data)
              #puts antenna_number.to_s + ' ' + regression_models[height][reader_power][antenna_number].to_s
              save_regression_model_into_db(height, reader_power, antenna_number, regression_models)
            end
            regression_models[height][reader_power][:all] = make_regression_model(data_array)
            #puts 'all ' + regression_models[height][reader_power][:all].to_s


            errors.push({
                :with => {
                    :by_one => regression_models[height][reader_power].select{|k,v|k != :all}.
                        map{|k,e|e[:errors_with_regression].to_f}.mean,
                    :all => regression_models[height][reader_power][:all][:errors_with_regression],
                },
                :without => {
                    :by_one => regression_models[height][reader_power].select{|k,v|k != :all}.
                        map{|k,e|e[:errors_without_regression].to_f}.mean,
                    :all => regression_models[height][reader_power][:all][:errors_without_regression],
                },
                :ellipse_ratio => @ellipse_ratio,
                :mi_power => @mi_power,
                :height => height,
                :reader_power => reader_power
            })

            save_regression_model_into_db(height, reader_power, :all, regression_models)
          end
        end





      end
    end


    errors
  end












  private




  def parse_for_antenna_mi_data(antenna, height, reader_power)
    mi_map = {}

    tags = MI::Base.parse()[reader_power][:tags][height]
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
    mi_transformed_values = []

    #puts antenna_number.to_s
    #puts TagInput.from_point(antenna.coordinates).id.to_s
    mi_map.each do |tag_position, mi|

      if mi != 0.0
        distances_values.push tag_position.distance_to_point(antenna.coordinates)
        angles_values.push antenna.coordinates.angle_to_point(tag_position)
        mi_values.push(mi)
        mi_transformed_values.push(mi ** @mi_power)

        #puts TagInput.from_point(tag_position).id.to_s + ': ' + mi.to_s + ' at ' +
        #    tag_position.distance_to_point(antenna.coordinates).to_s + ' angle: ' +
        #    to_degree( antenna.coordinates.angle_to_point(tag_position) ).to_s + '. - ' +
        #    ellipse(antenna.coordinates.angle_to_point(tag_position)).to_s
      end
    end



    #(0..2*Math::PI).step(Math::PI/20).each do |angle|
    #  puts to_degree(angle).to_s + ': ' + ellipse(angle).to_s
    #end


    [{
        :distances => distances_values,
        :mi => mi_values,
        :mi_t => mi_transformed_values,
        :angles => angles_values
    }]
  end







  def make_regression_model(data)
    mi = data.map{|vd| vd[:mi]}.flatten.to_vector(:scale)
    mi_t = data.map{|vd| vd[:mi_t]}.flatten.to_vector(:scale)
    angles = data.map{|vd|vd[:angles]}.flatten.map.with_index { |x, i| MI::Base.ellipse(x, @ellipse_ratio) * mi[i] }.to_vector(:scale)
    angles_t = data.map{|vd|vd[:angles]}.flatten.map.with_index { |x, i| MI::Base.ellipse(x, @ellipse_ratio) * mi_t[i] }.to_vector(:scale)
    distances = data.map{|vd|vd[:distances]}.flatten.to_vector(:scale)


    ds = {
        'a_mi' => mi,
        'a_mi_t' => mi_t,
        'b_angle' => angles,
        'b_angle_t' => angles_t,
        'y' => distances
    }.to_dataset
    if @mi_power == 1
      ds = {
          'a_mi' => mi,
          'y' => distances
      }.to_dataset
    end
    mlr = Statsample::Regression.multiple(ds, 'y')


    errors_with_regression = distances.map.with_index do |distance, i|
      if @mi_power == 1
        regression_distance = mlr.constant + mlr.coeffs['a_mi'] * mi[i]
      else
        regression_distance = (
            mlr.constant +
            mlr.coeffs['a_mi'] * mi[i] +
            mlr.coeffs['a_mi_t'] * mi_t[i] +
            mlr.coeffs['b_angle'] * angles[i] +
            mlr.coeffs['b_angle_t'] * angles_t[i]
        )
      end
      ( distance - regression_distance ).abs
    end
    errors_without_regression = mi.map.with_index do |mi,i|
      (distances[i] - @mi_class.to_distance_old( mi )).abs
    end

    {
        :const => mlr.constant,
        :mi_coeff => mlr.coeffs['a_mi'],
        :mi_coeff_t => mlr.coeffs['a_mi_t'],
        :angle_coeff => mlr.coeffs['b_angle'],
        :angle_coeff_t => mlr.coeffs['b_angle_t'],
        :errors_with_regression => errors_with_regression.mean,
        :errors_without_regression => errors_without_regression.mean
    }
  end









  def save_regression_model_into_db(height, reader_power, antenna_number, models)
    not_found = Regression::RegressionModel.where(:height => height,
        :reader_power => reader_power,
        :antenna_number => antenna_number.to_s,
        :type => @model_type,
        :mi_type => @mi_type).count == 0

    puts antenna_number.to_s + ' ' + models[height][reader_power][antenna_number].to_s

    if not_found and @add_to_db
      model = Regression::RegressionModel.new(
          {
              :mi_type => @mi_type,
              :type => @model_type,
              :height => height,
              :reader_power => reader_power,
              :antenna_number => antenna_number.to_s,
              :const => models[height][reader_power][antenna_number][:const],
              :mi_coeff => models[height][reader_power][antenna_number][:mi_coeff],
              :mi_coeff_t => models[height][reader_power][antenna_number][:mi_coeff_t],
              :angle_coeff => models[height][reader_power][antenna_number][:angle_coeff],
              :angle_coeff_t => models[height][reader_power][antenna_number][:angle_coeff_t]
          }
      )
      model.save
    end
  end

end