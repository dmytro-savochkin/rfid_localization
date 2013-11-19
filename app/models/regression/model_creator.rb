class Regression::ModelCreator
  def initialize
    @mi_type = :rss
    @mi_class = ('MI::' + @mi_type.to_s.capitalize).constantize
    @add_to_db = false

    #@model_type = 'powers=1,2,3__ellipse=1.5_watt'
    #@model_type = 'powers=1,2__ellipse=1.5_watt'
    #@model_type = 'powers=1__ellipse=1.5_watt'
    #@model_type = 'powers=1,2,3__ellipse=1.0_watt'
    #@model_type = 'powers=1,2__ellipse=1.0_watt'
    #@model_type = 'powers=1__ellipse=1.0_watt'

    #@model_type = 'powers=1,2,3__ellipse=1.5'
    #@model_type = 'powers=1,2__ellipse=1.5'
    #@model_type = 'powers=1__ellipse=1.5'
    #@model_type = 'powers=1,2,3__ellipse=1.0'
    #@model_type = 'powers=1,2__ellipse=1.0'
    #@model_type = 'powers=1__ellipse=1.0'

    @model_type = 'powers=1,2,3__ellipse=1.5_no_abs'
  end



  def create_models
    regression_models = {}
    errors = []

    #[1.01, 1.25, 1.5, 1.75, 2.0, 3.0, 4.0].each do |a_b_ratio|
    [1.5].each do |ellipse_ratio|
      @ellipse_ratio = ellipse_ratio
      #[1, 0.25, 0.33, 0.5, 2.0, 3.0, 4.0, 8.0, 16.0].each do |mi_power|
      [
          #[1.0], [1.0, 2.0], [1.0, 2.0, 3.0]
          #[1.0, 2.0, 3.0, 4.0]
          [1.0, 2.0, 3.0]
      ].each do |mi_powers|
        @mi_powers = mi_powers

        puts ellipse_ratio.to_s + ' _ ' + @mi_powers.to_s

        #MI::Base::HEIGHTS.each do |height|
        [MI::Base::HEIGHTS.first].each do |height|
          regression_models[height] ||= {}
          ((20..20).to_a).each do |reader_power|
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
                :correlation => {
                    :by_one => regression_models[height][reader_power].select{|k,v|k != :all}.
                        map{|k,e|e[:correlation].to_f}.mean,
                    :all => regression_models[height][reader_power][:all][:correlation],
                },
                :with => {
                    :by_one => regression_models[height][reader_power].select{|k,v|k != :all}.
                        map{|k,e|e[:errors_with_regression].to_f}.mean,
                    :all => regression_models[height][reader_power][:all][:errors_with_regression],
                },
                :ellipse_ratio => @ellipse_ratio,
                :mi_powers => @mi_powers,
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

    tags = MI::Base.parse_specific_tags_data(height, reader_power)
    tags.values.each do |tag|
      tag.answers[@mi_type][:average].each do |antenna_name, mi|
        #mi_map[tag.position] = mi.abs if antenna_name == antenna
        mi_map[tag.position] = mi if antenna_name == antenna
      end
    end

    mi_map
  end






  def create_regression_arrays(antenna_number, mi_map)
    antenna = Antenna.new(antenna_number)

    distances_values = []
    angles_values = []
    #mi_values = []
    mi_transformed_values = []


    mi_values = {}

    #puts antenna_number.to_s
    #puts TagInput.from_point(antenna.coordinates).id.to_s
    mi_map.each do |tag_position, mi|

      if mi != 0.0
        distances_values.push tag_position.distance_to_point(antenna.coordinates)
        angles_values.push antenna.coordinates.angle_to_point(tag_position)
        #mi_values.push(mi)
        #mi_transformed_values.push(mi ** @mi_power)

        @mi_powers.each do |mi_power|
          mi_values[mi_power] ||= []
          #mi_values[mi_power].push(MI::Rss.to_watt(mi) ** mi_power)
          mi_values[mi_power].push(mi ** mi_power)
        end



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
        #:mi_t => mi_transformed_values,
        :angles => angles_values
    }]
  end







  def make_regression_model(data)
    #mi = data.map{|vd| vd[:mi]}.flatten.to_vector(:scale)
    #mi_t = data.map{|vd| vd[:mi_t]}.flatten.to_vector(:scale)
    #angles_t = data.map{|vd|vd[:angles]}.flatten.map.with_index { |x, i| MI::Base.ellipse(x, @ellipse_ratio) * mi_t[i] }.to_vector(:scale)
    #angles = data.map{|vd|vd[:angles]}.flatten.map.with_index { |x, i| MI::Base.ellipse(x, @ellipse_ratio) * mi[i] }.to_vector(:scale)
    distances = data.map{|vd|vd[:distances]}.flatten

    regression_data_set = {
        'y' => distances.to_vector(:scale)
    }



    mi = {}
    angles = {}

    @mi_powers.each do |mi_power|
      mi[mi_power] = data.map{|vd| vd[:mi][mi_power]}.flatten
      regression_data_set['mi_' + mi_power.to_s] = mi[mi_power].to_vector(:scale)
    end

    if @ellipse_ratio != 1.0
      angles = data.map{|vd|vd[:angles]}.flatten.map.with_index do |x, i|
        MI::Base.ellipse(x, @ellipse_ratio) * mi[1.0][i]
      end
      regression_data_set['angles'] = angles.to_vector(:scale)
    end




    regression_data_set = regression_data_set.to_dataset
    regression_model = Statsample::Regression.multiple(regression_data_set, 'y')




    regression_distances = distances.map.with_index do |distance, i|
      regression_distance = regression_model.constant

      @mi_powers.each do |mi_power|
        regression_distance += regression_model.coeffs['mi_' + mi_power.to_s] * mi[mi_power][i]
      end
      if @ellipse_ratio != 1.0
        regression_distance += regression_model.coeffs['angles'] * angles[i]
      end

      regression_distance
    end




    errors_with_regression = regression_distances.map.with_index do |regression_distance, i|
      (distances[i] - regression_distance).abs
    end



    mi_coeffs = {}
    @mi_powers.each do |mi_power|
      mi_coeffs[mi_power] = regression_model.coeffs['mi_' + mi_power.to_s]
    end
    angles_coeffs = regression_model.coeffs['angles']



    {
        :const => regression_model.constant,
        :mi_coeffs => mi_coeffs,
        :angle_coeffs => angles_coeffs,
        :errors_with_regression => errors_with_regression.mean,
        :correlation => Math.correlation(distances, regression_distances)
    }
  end














  def save_regression_model_into_db(height, reader_power, antenna_number, models)
    not_found = Regression::RegressionModel.where(
        :height => height,
        :reader_power => reader_power,
        :antenna_number => antenna_number.to_s,
        :type => @model_type,
        :mi_type => @mi_type
    ).count == 0

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
              :mi_coeff => models[height][reader_power][antenna_number][:mi_coeffs].to_json,
              :angle_coeff => models[height][reader_power][antenna_number][:angle_coeffs],
          }
      )
      model.save
    end
  end

end