class Algorithm::PointBased::Probabilistic::Combiner < Algorithm::PointBased

  def set_settings(point_stepper, to_weight)
    @optimization = Optimization::MaximumProbability.new
    @point_stepper = point_stepper
    @zones_creator = Algorithm::PointBased::Zonal::ZonesCreator.new(
        @work_zone, :ellipses, @reader_power, @point_stepper.step
    )

    @regression_type = 'new'
    @model_type = 'circular'
    @antenna_type = :specific

    @metric_name = :rss
    @mi_class = MI::Base.class_by_mi_type(@metric_name)

    if to_weight
      @weighting = {:knn => 0.8, :tri => 0.2}
    end

    self
  end




  private








  def train_model(tags_train_input, height)

    cache_name = 'coverage_zones_' + @reader_power.to_s + '_ellipses'
    coverage_zones = Rails.cache.fetch(cache_name, :expires_in => 1.year) do
      @zones_creator.create_coverage_zones.each{|k,set| set.keep_if{|point| Point.from_a(point).within_tags_boundaries?}}
    end

    cache_name = 'elementary_zones_' + @reader_power.to_s + '_ellipses'
    elementary_zones = Rails.cache.fetch(cache_name, :expires_in => 1.year) do
      @zones_creator.create_elementary_zones.each{|k,ary| ary.keep_if{|point| point.within_tags_boundaries?}}
    end

    table = {}
    tags_train_input.each do |index, tag|
      table[tag.position.to_s] = tag_answers_hash(tag)
    end
    table

    {
        :height => height,
        :table => table,
        :coverage_zones => coverage_zones,
        :elementary_zones => elementary_zones
    }
  end


  def model_run_method(model, tag)
    @train_height = model[:height]
    zonal_data = zonal(model[:coverage_zones], model[:elementary_zones], tag)
    probabilities = {}

    puts tag.id.to_s

    tag_vector = tag_answers_hash(tag)

    probs = {:knn => {}, :tri => {}}
    zonal_data[:resulting_zone].each do |point_as_a|
      point = Point.from_a(point_as_a)
      probs[:knn][point_as_a] = knn(model[:table], tag_vector, point)
      probs[:tri][point_as_a] = trilateration(tag, point)
    end
    max = {}
    max[:knn] = probs[:knn].values.max
    max[:tri] = probs[:tri].values.max

    zonal_data[:resulting_zone].each do |point_as_a|
      point = Point.from_a(point_as_a)

      if @weighting.present?
        probabilities[point] =
            @weighting[:knn] * probs[:knn][point_as_a] / max[:knn] +
            @weighting[:tri] * probs[:tri][point_as_a] / max[:tri]
      else
        probabilities[point] = probs[:knn][point_as_a] * probs[:tri][point_as_a]
      end
    end




    make_estimate(probabilities)
  end





  def make_estimate(probabilities)
    probabilities.max_by{|point, probability| probability}[0]
  end









  def zonal(coverage_zones, elementary_zones, tag)
    answered_antennas = []
    tag.answers[:a][:average].keys.each do |antenna|
      if tag.answers[:rss][:average][antenna].present? and tag.answers[:rss][:average][antenna].to_f > -71.0
        answered_antennas.push antenna
      end
    end
    answered_antennas = tag.answers[:a][:average].select{|k,v|v == 1}.keys if answered_antennas.empty?
    not_answered_antennas = (1..16).to_a - answered_antennas.to_a

    not_answered_union_zone = Rails.cache.fetch('union_zone_' + not_answered_antennas.to_s, :expires_in => 1.year) do
      coverage_zones.select{|a, points| not_answered_antennas.include? a}.values.inject(&:union)
    end

    answered_intersection_zone = Rails.cache.fetch('intersection_zone_' + answered_antennas.to_s, :expires_in => 1.year) do
      coverage_zones.select{|a, points| answered_antennas.include? a}.values.inject(&:intersection)
    end

    resulting_zone = Rails.cache.fetch('resulting_zone_' + answered_antennas.to_s, :expires_in => 1.year) do
      answered_intersection_zone - not_answered_union_zone
    end

    if resulting_zone.empty?
      found_zones = []
      answered_antennas.length.downto(1) do |length|
        combinations = answered_antennas.combination(length)
        combinations.each do |combination|
          if elementary_zones.keys.include? (combination.to_s)
            found_zones.push elementary_zones[combination.to_s].to_set
          end
        end
        break if found_zones.present?
      end

      resulting_zone = found_zones.inject(&:union)
    end

    {:resulting_zone => resulting_zone}
  end




  def trilateration(tag, point)
    mi_hash = tag.answers[:rr][:average]
    distances = get_distances_by_mi(mi_hash)

    real_distances = {}
    distances.keys.map do |antenna_number|
      antenna = @work_zone.antennae[antenna_number]
      ac = antenna.coordinates
      real_distances[antenna_number] = Math.sqrt((ac.x.to_f - point.x) ** 2 + (ac.y.to_f - point.y) ** 2)
    end

    @optimization.compare_vectors(
        real_distances,
        distances,
        {},
        10**5
    )
  end

  def get_distances_by_mi(mi_hash)
    MI::Rr.distances_hash(
        mi_hash,
        mi_hash.dup,
        @reader_power,
        @regression_type,
        @train_height,
        @antenna_type,
        @model_type
    )
  end




  def knn(table, tag_vector, point)
    table_vector = create_table_vector(table, point)

    @optimization.compare_vectors(
        tag_vector,
        table_vector,
        {},
        10**5
    )
  end

  def create_table_vector(table, point)
    return table[point.to_s] if table[point.to_s].present?

    table_vector = {}
    nearest_tags_coords = point.nearest_tags_coords

    nearest_tags_answers = table.select{|p, tag| nearest_tags_coords.include? p}

    if nearest_tags_answers.length == 0
      table_vector = tag_answers_empty_hash
    elsif nearest_tags_answers.length == 1
      table_vector = nearest_tags_answers.values.first
    else
      distances_to_tags = {}

      nearest_tags_answers.each do |nearest_tag_point, nearest_tag_answers|
        distances_to_tags[nearest_tag_point] = Point.distance(point, Point.from_s(nearest_tag_point))
      end

      weighting_denominator = distances_to_tags.map{|k, distance| 1.0 / distance}.sum
      nearest_tags_answers.each do |k, nearest_tag|
        rate = (1.0 / distances_to_tags[k]) / weighting_denominator
        (1..16).each do |antenna|
          table_vector[antenna] ||= 0.0
          table_vector[antenna] += rate * nearest_tag[antenna]
        end
      end
    end

    table_vector
  end




end