class Regression::ViewerDistancesMi
  def initialize(mi_type)
		@mi_type = mi_type
  end

  def get_data
    graph_data = {}
    graph_limits = {}
    coefficients = {}
    correlation = {}
		real_mi_and_distances = {}
    polynomial_degrees = [2, 3]

    (20..30).each do |reader_power|
      graph_data[reader_power] ||= {}
      coefficients[reader_power] ||= {}
      correlation[reader_power] ||= {}
      graph_limits[reader_power] = get_graph_limits(reader_power)
			real_mi_and_distances[reader_power] = get_real_mi_and_distances(reader_power)
			polynomial_degrees.each do |degree|
        coefficients[reader_power][degree] = get_polynomial(reader_power, degree)
        graph_data[reader_power][degree] = get_graph_data(coefficients[reader_power][degree])
        correlation[reader_power][degree] = calculate_correlation(coefficients[reader_power][degree], real_mi_and_distances[reader_power])
      end
    end

    [graph_data, graph_limits, coefficients, correlation, real_mi_and_distances]
  end



  private

  def get_polynomial(reader_power, polynomial_degree)
    type = 'powers=' + (1..polynomial_degree).to_a.join(',') + '__ellipse=1.0'

    model = Regression::DistancesMi.where(
        :height => 'all',
        :reader_power => reader_power,
        :antenna_number => 'all',
        :type => type,
        :mi_type => @mi_type
    ).first

    parsed_coeffs = JSON.parse(model.mi_coeff)
    coeffs = []
    coeffs[0] = model.const.to_f
    parsed_coeffs.each do |k, mi_coeff|
      unless mi_coeff.nil?
        coeffs.push mi_coeff.to_f
      end
    end
    coeffs
  end

  def get_graph_limits(reader_power)
    limits = Regression::MiBoundary.where(
        :reader_power => reader_power,
        :type => @mi_type
    ).first

    [limits.min, limits.max]
  end

  def get_graph_data(coefficients)
    data = []
		range = (0..1).step(0.001)
		range = (-85..-50).step(0.1) if @mi_type == :rss
    range.each do |mi|
      distance = coefficients[0]
      coefficients[1..-1].each_with_index do |coefficient, index|
        degree = index + 1
        distance += coefficient * mi ** degree
      end
      data.push([mi, distance])
    end
    data
  end






  def get_real_mi_and_distances(reader_power)
    data = []
    MI::Base::HEIGHTS.each do |height|
      responded_tags = MI::Base.parse_specific_tags_data(height, reader_power)
      responded_tags.values.each do |tag|
        tag.answers[@mi_type][:average].each do |antenna_number, mi|
          antenna = Antenna.new(antenna_number)
          distance = antenna.coordinates.distance_to_point(tag.position)
          data.push([mi, distance])
        end
      end
    end
    data
  end


  def calculate_correlation(coefficients, real_mi_and_distances)
    distances = []
    regression_distances = []

    real_mi_and_distances.each do |mi_and_distance|
      distance = mi_and_distance.last
      mi = mi_and_distance.first

      regression_distance = coefficients[0]
      coefficients[1..-1].each_with_index do |coefficient, index|
        degree = index + 1
        regression_distance += coefficient * mi ** degree
      end

      distances.push distance
      regression_distances.push regression_distance
    end


    Math.correlation(distances, regression_distances)
  end

end