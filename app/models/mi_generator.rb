class MiGenerator
  def initialize
    @antennae_accuracy = {}
    (1..16).each{|antenna_number| @antennae_accuracy[antenna_number] = 0.8}
    #@antennae_accuracy[5] = 0.1
    #@antennae_accuracy[11] = 0.1

    #@rss_std_dev = 0.5
    #@distance_std_dev = 10.0

    @rss_limits = create_rss_limits
  end






  def create_group(count, positions, reader_power, height_number)
    set_rss_model(reader_power, height_number)

    tags = {}
    count.times do |number|
      tags[number.to_s] = create(number.to_s, positions[number], @rss_limits[reader_power])
    end
    tags
  end







  def create_positions(count)
    positions = []
    count.times do
      positions.push random_position
    end
    positions
  end







  private


  def create(tag_id, position, rss_limit)
    tag = TagInput.new(tag_id.to_s, 16, position)

    best_antenna_rss_pair = [nil, -1.0/0.0]
    (1..16).each do |antenna_number|
      antenna = Antenna.new(antenna_number)

      antenna_tag_distance = Point.distance(tag.position, antenna.coordinates)
      antenna_tag_angle = antenna.coordinates.angle_to_point(tag.position)

      rss = generate_rss(
          antenna_tag_distance,
          antenna_tag_angle,
          @antennae_accuracy[antenna_number],
          antenna_number
      )
      best_antenna_rss_pair = [antenna_number, rss] if rss > best_antenna_rss_pair[1]
      if rss > rss_limit
        rr = generate_rr(rss)
        add_answers_to_tag(tag, antenna_number, rss, rr)
      end
    end

    if tag.answers_count == 0
      antenna_number = best_antenna_rss_pair[0]
      rss = best_antenna_rss_pair[1]
      add_answers_to_tag(tag, antenna_number, rss, generate_rr(rss))
    end

    tag
  end




  def set_rss_model(reader_power, height_number)
    @rss_model = {}
    (1..16).each do |antenna_number|
      @rss_model[antenna_number] = Regression::RegressionModel.where({
          :height => MI::Base::HEIGHTS[height_number],
          :reader_power => reader_power,
          :antenna_number => 'all',
          :mi_type => 'rss',
          :type => 'powers=1__ellipse=1.5'
      }).first
    end
  end

  def create_rss_limits()
    rss_limit = {}
    (20..30).each do |reader_power|
      rss_limit[reader_power] = -73.0
      rss_limit[reader_power] = -71.0 if reader_power == -71.0
      rss_limit[reader_power] = -72.0 if reader_power == -72.0 or reader_power == -73.0
    end
    rss_limit
  end


  def add_answers_to_tag(tag, antenna_number, rss, rr)
    tag.answers_count += 1
    tag.answers[:a][:average][antenna_number] = 1
    tag.answers[:a][:adaptive][antenna_number] = 1 if rss > -70.0
    tag.answers[:rss][:average][antenna_number] = rss
    tag.answers[:rss][:adaptive][antenna_number] = rss if rr > 0.1
    tag.answers[:rr][:average][antenna_number] = rr
  end

  def generate_rss(accurate_distance, angle, antenna_accuracy, antenna_number)
    distance_error_std_dev =
        Antenna::ERROR_LIMITS[:rss] -
        Antenna::ERROR_LIMITS[:rss] * antenna_accuracy
    distance_error =
        #Math.rayleigh_value(distance_error_expected_value) * [1.0, -1.0].sample
        #Rubystats::NormalDistribution.new(distance_error_ev, @distance_std_dev).rng.to_f
        Rubystats::NormalDistribution.new(0, distance_error_std_dev).rng.to_f
    distance = accurate_distance + distance_error


    mi_coeffs = JSON.parse(@rss_model[antenna_number].mi_coeff)
    mi_coeff = mi_coeffs['1.0']
    rss =
        (distance - @rss_model[antenna_number].const.to_f) /
        (-mi_coeff.to_f - @rss_model[antenna_number].angle_coeff.to_f * MI::Base.ellipse(angle, 1.5))
    #normal_distribution = Rubystats::NormalDistribution.new(rss, @rss_std_dev)
    #normal_distribution.rng.to_f
    rss
  end

  def generate_rr(rss)
    0.0
  end


  def random_position
    Point.new(rand(WorkZone::WIDTH), rand(WorkZone::HEIGHT))
  end
end