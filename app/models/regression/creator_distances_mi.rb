class Regression::CreatorDistancesMi

  def initialize
    @mi_type = :rss
    @add_to_db = false
    @mi_class = ('MI::' + @mi_type.to_s.capitalize).constantize

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

    #@model_type = 'powers=1,2,3__ellipse=1.5_no_abs'
    @model_type = 'powers=1,2,3__ellipse=1.0'
  end


  def create_models
    regression_models = {}
    deviations = {}
    deviations_normality = {}
    errors = []

    #[1.01, 1.25, 1.5, 1.75, 2.0, 3.0, 4.0].each do |a_b_ratio|
    [1.0].each do |ellipse_ratio|
      deviations[ellipse_ratio] ||= {}
      deviations_normality[ellipse_ratio] ||= {}
      @ellipse_ratio = ellipse_ratio
      [
          #[1.0], [1.0, 2.0], [1.0, 2.0, 3.0]
          #[1.0, 2.0, 3.0, 4.0],
          [1.0, 2.0, 3.0],
          [1.0, 2.0],
      #[1.0, 2.0],
      #[1.0],
      ].each do |degrees_set|
        deviations[ellipse_ratio][degrees_set.max.to_f] ||= {}
        deviations_normality[ellipse_ratio][degrees_set.max.to_f] ||= {}
        @degrees_set = degrees_set
        max_set_degree = degrees_set.max.to_f

        puts ellipse_ratio.to_s + ' _ ' + @degrees_set.to_s

        #MI::Base::HEIGHTS.each do |height|
        (20..30).to_a.each do |reader_power|

          current_power_data_array = []
          regression_models[reader_power] ||= {}
          MI::Base::HEIGHTS.each do |height|
            regression_models[reader_power][height] ||= {}

            data_array = []
            (1..16).each do |antenna_number|
              mi_map = parse_for_antenna_mi_data(antenna_number, height, reader_power)
              data = create_regression_arrays(antenna_number, mi_map)
              data_array.push data.first
              current_power_data_array.push data.first
              regression_models[reader_power][height][antenna_number] = make_regression_model(data)
              save_regression_model_into_db(height, reader_power, antenna_number, regression_models)
            end

            regression_models[reader_power][height][:all] = make_regression_model(data_array)

            errors.push({
                :correlation => {
                    :by_one => regression_models[reader_power][height].select{|k,v|k != :all}.
                        map{|k,e|e[:correlation].to_f}.mean,
                    :all => regression_models[reader_power][height][:all][:correlation],
                },
                :with => {
                    :by_one => regression_models[reader_power][height].select{|k,v|k != :all}.
                        map{|k,e|e[:errors_with_regression].to_f}.mean,
                    :all => regression_models[reader_power][height][:all][:errors_with_regression],
                },
                :ellipse_ratio => @ellipse_ratio,
                :degrees_set => @degrees_set,
                :height => height,
                :reader_power => reader_power
            })

            save_regression_model_into_db(height, reader_power, :all, regression_models)
          end

          regression_models[reader_power][:all] = make_regression_model(current_power_data_array)

          save_regression_model_into_db(:all, reader_power, :all, regression_models)

          deviations[ellipse_ratio][degrees_set.max.to_f][reader_power] = calculate_measurements_deviation(regression_models[reader_power][:all], current_power_data_array, reader_power)
          deviations_normality[ellipse_ratio][max_set_degree][reader_power] =
              test_deviations_normality(deviations[ellipse_ratio][max_set_degree][reader_power])
        end

      end
    end

    [regression_models, errors, deviations, deviations_normality]
  end





















  private

  def calculate_measurements_deviation(model, data, reader_power)
    #d = a0 + (a1 + a4*e)*RSS + a2*RSS^2 + a3*RSS^3
    deviations = []

    coeffs = []
    coeffs[0] = model[:const].to_f
    angle_coeff = nil
    angle_coeff = model[:angle_coeffs] if model[:angle_coeffs] != nil
    model[:mi_coeffs].each do |k, mi_coeff|
      unless mi_coeff.nil?
        coeffs.push mi_coeff.to_f
      end
    end

    strict_mi_range = {:min => 9999999.0, :max => -9999999.0}
    data.each do |group_data|
      group_data[:mi][1.0].each do |mi|
        strict_mi_range[:min] = mi if mi < strict_mi_range[:min]
        strict_mi_range[:max] = mi if mi > strict_mi_range[:max]
      end
    end
    strict_mi_range_center = strict_mi_range[:max] - (strict_mi_range[:max] - strict_mi_range[:min])/2


    if Regression::MiBoundary.where(:type => @mi_type, :reader_power => reader_power).count == 0
      mi_boundary = Regression::MiBoundary.new(
          {
              :min => strict_mi_range[:min],
              :max => strict_mi_range[:max],
              :type => @mi_type,
              :reader_power => reader_power
          }
      )
      mi_boundary.save
    end


    data.each do |group_data|
      group_data[:distances].each_with_index do |distance, i|
        real_mi = group_data[:mi][1.0][i].to_f
        angle = group_data[:angles][i]

        regression_mi = @mi_class.regression_root(
            @ellipse_ratio,
            angle,
            distance,
            strict_mi_range.values,
            strict_mi_range_center,
            coeffs,
            angle_coeff
        )

        deviations.push(real_mi - regression_mi)
      end
    end

    deviations.sort
  end


  def test_deviations_normality(deviations)
    #require 'rinruby'
    #puts deviations.to_s.gsub(/[\[\]]/, '')
    #puts "test_result <- toString(shapiro.test(c(#{deviations.to_s.gsub(/[\[\]]/, '')})))"
    #R.eval('test_result <- toString(shapiro.test(c(-6.8560215771478425, -6.339849985719944, -5.8560215771478425, -5.726031661279897, -5.339849985719944)))')
    #rinruby = RinRuby.new(echo = false)
    #rinruby.eval "test_result <- toString(shapiro.test(c(#{deviations.to_s.gsub(/[\[\]]/, '')})))"
    #puts rinruby.pull("test_result").to_s
    #test_p_value = rinruby.pull("test_result").split(',')[1]
    #puts "===normality is " + test_p_value.to_s
    #test_p_value
    'unknown yet'
  end


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

        @degrees_set.each do |degree|
          mi_values[degree] ||= []
          #mi_values[degree].push(MI::Rss.to_watt(mi) ** degree)
          mi_values[degree].push(mi ** degree)
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

    @degrees_set.each do |degree|
      mi[degree] = data.map{|vd| vd[:mi][degree]}.flatten
      regression_data_set['mi_' + degree.to_s] = mi[degree].to_vector(:scale)
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

      @degrees_set.each do |degree|
        regression_distance += regression_model.coeffs['mi_' + degree.to_s] * mi[degree][i]
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
    @degrees_set.each do |degree|
      mi_coeffs[degree] = regression_model.coeffs['mi_' + degree.to_s]
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
    not_found = Regression::DistancesMi.where(
        :height => height,
        :reader_power => reader_power,
        :antenna_number => antenna_number.to_s,
        :type => @model_type,
        :mi_type => @mi_type
    ).count == 0

    if height == :all
      model = models[reader_power][:all]
    else
      model = models[reader_power][height][antenna_number]
    end

    puts antenna_number.to_s + ' ' + model.to_s

    if @add_to_db
      if not_found
        model = Regression::DistancesMi.new(
            {
                :mi_type => @mi_type,
                :type => @model_type,
                :height => height,
                :reader_power => reader_power,
                :antenna_number => antenna_number.to_s,
                :const => model[:const],
                :mi_coeff => model[:mi_coeffs].to_json,
                :angle_coeff => model[:angle_coeffs],
            }
        )
        model.save
      end
    end
  end


end