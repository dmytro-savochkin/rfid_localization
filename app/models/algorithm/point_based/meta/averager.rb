class Algorithm::PointBased::Meta::Averager < Algorithm::PointBased

  attr_reader :algorithms, :group

  def initialize(algorithms, manager_id, group, tags_input)
    @algorithms = algorithms
    @tags_input = tags_input
    @manager_id = manager_id
    @group = group
  end


  def set_settings(apply_stddev_weighting, correlation_weighting, special_case_one_antenna, special_case_small_variances, apply_centroid_weighting, variance_decrease_coefficient, averaging_type, tags_count_for_correlation, weights = [])
    @apply_stddev_weighting = apply_stddev_weighting
    @correlation_weighting = correlation_weighting
    @special_case_one_antenna = special_case_one_antenna
    @special_case_small_variances = special_case_small_variances
    @variance_decrease_coefficient = variance_decrease_coefficient
    @apply_centroid_weighting = apply_centroid_weighting

    @averaging_type = averaging_type
    @tags_count_for_correlation = tags_count_for_correlation
    @weights = weights
    self
  end









  private

  def train_model(train_data, heights, model_id)
  end

  def set_up_model(model, train_data, setup_data, height_index)
    correlation_weights = []
    correlation_weights_x = []
    correlation_weights_y = []

    # может быть в будущем вернуться к постоянному добавлению новых оценок с пересчетом к-тов

    correlations_methods = {
        :rv => :rv_coefficient,
        :brownian => :brownian_correlation
    }

    if @correlation_weighting
      correlation = {}
      correlation_x = {}
      correlation_y = {}

      @algorithms.values.each_with_index do |algorithm1, index1|
        #estimates1 = algorithm1.setup[height_index][:estimates]
        #estimates1 = Hash[algorithm1.setup[height_index][:estimates].sort_by{|k,v|k}[0...@tags_count_for_correlation]]

        if @tags_count_for_correlation == nil
          estimates1 = Hash[algorithm1.setup[height_index][:estimates].sort_by{|k,v|k}]
        else
          estimates1 = Hash[algorithm1.setup[height_index][:estimates].sort_by{|k,v|k}[0...@tags_count_for_correlation]]
        end

        #puts estimates1.values.to_s


        correlation[index1] ||= {}
        #correlation_x[index1] ||= {}
        #correlation_y[index1] ||= {}

        @algorithms.values.each_with_index do |algorithm2, index2|
          #puts algorithm2.setup[height_index].to_s
          if @tags_count_for_correlation == nil
            estimates2 = Hash[algorithm2.setup[height_index][:estimates].sort_by{|k,v|k}]
          else
            estimates2 = Hash[algorithm2.setup[height_index][:estimates].sort_by{|k,v|k}[0...@tags_count_for_correlation]]
          end


          #if @tags_count_for_correlation == nil
          #  if estimates1.keys.to_s != estimates2.keys.to_s
          #    puts algorithm1.to_s + ' ' + algorithm2.to_s
          #    puts estimates1.keys.to_s
          #    puts estimates2.keys.to_s
          #    puts ''
          #  end
          #end





          if estimates1.length != estimates2.length
            keys_to_keep = [estimates1.keys, estimates2.keys].sort_by(&:length)[0]
            estimates1 = estimates1.keep_if{|k,v| keys_to_keep.include? k}
            estimates2 = estimates2.keep_if{|k,v| keys_to_keep.include? k}
          end

          #puts 'e2 ' + estimates1.values.map{|p| [p.x, p.y]}.to_s

          #puts estimates1.values.map{|p| [p.x, p.y]}.to_s
          #puts estimates2.values.map{|p| [p.x, p.y]}.to_s
          #puts ''

          points1 = estimates1.values.map{|p| [p.x, p.y]}
          #points1_x = estimates1.values.map{|p| p.x}
          #points1_y = estimates1.values.map{|p| p.y}
          points2 = estimates2.values.map{|p| [p.x, p.y]}
          #points2_x = estimates2.values.map{|p| p.x}
          #points2_y = estimates2.values.map{|p| p.y}

          correlation[index1][index2] = Math.send(
              correlations_methods[@correlation_weighting],
              points1,
              points2
          )

          #correlation_x[index1][index2] = Math.correlation(points1_x, points2_x)
          #correlation_y[index1][index2] = Math.correlation(points1_y, points2_y)

          #puts correlation[index1][index2].to_s
          #puts Math.rv_coefficient(
          #    estimates1.values.map{|p| [p.x, p.y]},
          #    estimates2.values.map{|p| [p.x, p.y]}
          #)
        end

        #puts algorithm1.to_s
        #puts correlation[index1].to_s
        #puts ''

        correlation_weights.push(correlation[index1].values.map{|corr| 1.0 / corr}.sum)
        #correlation_weights_x.push(correlation_x[index1].values.map{|corr| 1.0 / corr}.sum)
        #correlation_weights_y.push(correlation_y[index1].values.map{|corr| 1.0 / corr}.sum)
      end

      #puts @correlation_weighting.to_s
      #puts correlation.to_yaml
      #puts correlation_weights.to_yaml
      #puts correlation_weßights_x.to_yaml
      #puts correlation_weights_y.to_yaml
      #puts ''

    end

    correlation_weights
  end

  #def update_correlation_weights(height_index, new_estimates)
  #  correlation_weights = []
  #
  #  if @correlation_weighting
  #    correlation = {}
  #
  #    @algorithm_estimates ||= {}
  #
  #    if @algorithm_estimates[height_index].nil?
  #      @algorithm_estimates[height_index] = {}
  #      @algorithms.values.each_with_index do |algorithm, index|
  #        @algorithm_estimates[height_index][index] =
  #            algorithm.setup[height_index][:estimates].values
  #      end
  #    end
  #
  #    new_estimates.each_with_index do |new_estimate, index|
  #      @algorithm_estimates[height_index][index].push new_estimate
  #    end
  #
  #    #puts @algorithm_estimates[height_index].to_s
  #
  #    @algorithm_estimates[height_index].values.each_with_index do |estimates1, index1|
  #      correlation[index1] ||= {}
  #      @algorithm_estimates[height_index].values.each_with_index do |estimates2, index2|
  #        correlation[index1][index2] =
  #            #Math.rv_coefficient(
  #            Math.brownian_correlation(
  #                estimates1.map{|p| [p.x, p.y]},
  #                estimates2.map{|p| [p.x, p.y]}
  #            )
  #      end
  #      correlation_weights.push(correlation[index1].values.map{|corr| 1.0 - corr}.sum)
  #    end
  #  end
  #
  #  correlation_weights
  #end




  def calc_tags_estimates(model, setup, tags_input, height_index)
    tags_estimates = {}

    tags_input.each do |tag_index, tag|
      estimate = make_estimate(setup, tag, height_index)
      tag_output = TagOutput.new(tag, estimate)
      tags_estimates[tag_index] = tag_output
    end

    tags_estimates
  end







  def make_estimate(setup, tag, height_index)
    tag_index = tag.id.to_s

    correlation_weights = setup[height_index]

    #correlation_weights = update_correlation_weights(
    #    height_index,
    #    #@algorithms.values.map{|a| a.map[height_index][tag_index][:estimate]}
    #    []
    #)

    all_points = []
    hash = {}

    stddev_weights = generate_stddev_weights(tag_index, height_index)

    @algorithms.each_with_index do |(algorithm_name, algorithm), i|
      if algorithm.map[height_index][tag_index].present?
        answers_count = algorithm.map[height_index][tag_index][:answers_count]

        point = algorithm.map[height_index][tag_index][:estimate].to_s
        hash[point] ||= {:point => 0, :weight => 0.0}
        hash[point][:point] += 1

        all_points.push algorithm.map[height_index][tag_index][:estimate]

        if @weights.present?
          if @weights[i][answers_count.to_s].present?
            weight = @weights[i][answers_count.to_s]
          elsif @weights[i][:other].present?
            weight = @weights[i][:other]
          else
            weight = 0.0
          end
          hash[point][:weight] += weight
        end
      end
    end

    #return nil if points_hash.empty?
    #puts train_height.to_s + ' - ' + test_height.to_s + ' ' + tag.id.to_s + ': ' + weights.to_s

    #puts all_points.to_s


    points = all_points
    points = hash.keys.map{|point_string| Point.from_s(point_string)} if @averaging_type == :equal

    centroid_weights = generate_centroid_weights(points)

    weights = []
    weights = hash.values.map{|h| h[:weight]} if @weights.present?


    #puts tag_index.to_s

    #puts 'TTT' if tag_answers_counts[0] == 1
    ##if @apply_stddev_weighting
    #  #puts stddev_weights.to_s
    #  #puts tag_answers_counts.to_s
    #  #puts variances.to_s
    #  #puts @algorithms.values.
    #  #    map.with_index{|a, i| a.setup[height_index][:lengths][tag_answers_counts[i]]}.to_s
    ##end
    ##puts small_variance_points.to_s

    #puts points.to_s
    #puts stddev_weights.to_s
    #puts correlation_weights.to_s

    result_weights = []
    points.each_with_index do |point, i|
      result_weights[i] = 1.0
      result_weights[i] *= stddev_weights[i] if stddev_weights[i].present?
      result_weights[i] *= correlation_weights[i] if correlation_weights[i].present?
      result_weights[i] *= weights[i] if weights[i].present?
      result_weights[i] *= centroid_weights[i] if centroid_weights[i].present?
    end


    #puts result_weights.to_s
    #puts ''


    result_weights = [] if result_weights.all?{|w|w.zero?}

    Point.center_of_points(points, result_weights)
  end





  def generate_centroid_weights(points)
    centroid_weights = []
    if @apply_centroid_weighting
      centroid = Point.center_of_points(points)
      distances_to_centroid = points.map{|point| Point.distance(point, centroid)}
      min_distance = 10.0
      max_distance = 100.0
      distances_to_centroid.each do |distance_to_centroid|
        if distance_to_centroid < min_distance
          centroid_weights.push 1.0
        elsif distance_to_centroid > max_distance
          centroid_weights.push 0.00
        else
          centroid_weights.push( (max_distance - distance_to_centroid) / max_distance )
        end
      end
    end
    centroid_weights
  end

  def generate_stddev_weights(tag_index, height_index)
    small_variance_points = []


    variance_limit = 15.0
    small_variances_limit = 4

    stddev_weights = []

    tag_answers_counts = []
    @algorithms.values.each_with_index do |algorithm, i|
      if algorithm.map[height_index][tag_index].present?
        tag_answers_counts.push(
            algorithm.tags_input[height_index][:test][tag_index].answers_count
        )
      end
    end



    if @apply_stddev_weighting

      if @apply_stddev_weighting == :all
        stddevs_objects = @algorithms.values.
            map.with_index{|a, i| a.setup[height_index][:stddevs][:all]}
        #means_objects = @algorithms.values.
        #    map.with_index{|a, i| a.setup[height_index][:means][:all]}
      else
        stddevs_objects = @algorithms.values.
            map.with_index{|a, i| a.setup[height_index][:stddevs][tag_answers_counts[i]]}
        #means_objects = @algorithms.values.
        #    map.with_index{|a, i| a.setup[height_index][:means][tag_answers_counts[i]]}
      end

      #means = means_objects.map do |means_object|
      #  if means_object.nil?
      #    Float::NAN
      #  else
      #    means_object[:total]
      #  end
      #end
      stddevs = stddevs_objects.map do |stddev_object|
        if stddev_object.nil?
          Float::NAN
        else
          #stddev_object[:total]
          Math.sqrt(stddev_object[:x] * stddev_object[:y])
        end
      end
      variances = stddevs.map{|stddev| stddev ** 2}
      #sum_of_inverted_means = means.map{|mean| 1.0/mean}.reject{|v|v.nan?}.sum

      @algorithms.values.each_with_index do |algorithm, i|
        if algorithm.map[height_index][tag_index].present?
          if @apply_stddev_weighting == :all
            tags_count_with_that_answers_count = algorithm.
                setup[height_index][:lengths][:all].to_i
          else
            tags_count_with_that_answers_count = algorithm.
                setup[height_index][:lengths][tag_answers_counts[i]].to_i
          end

          if tags_count_with_that_answers_count > 2

            if algorithm.trainable and algorithm.model_must_be_retrained
              variance = variances[i] * @variance_decrease_coefficient.to_f
              stddev = stddevs[i] * @variance_decrease_coefficient.to_f
              #mean = means[i] * @variance_decrease_coefficient.to_f
            else
              variance = variances[i]
              stddev = stddevs[i]
              #mean = means[i]
            end

            #stddev_weight = 1.0 / (mean + variance)
            stddev_weight = 1.0 / variance

            if @special_case_small_variances
              if stddevs[i] <= variance_limit
                small_variance_points.push i
              end
            end

          else
            stddev_weight = Float::NAN
          end

          stddev_weights.push(stddev_weight)
        end
      end


      if stddev_weights.all?{|w| w.nan?}
        stddev_weights = []
      else
        stddev_weights_mean = stddev_weights.reject{|w| w.nan?}.mean
        stddev_weights.each_with_index do |stddev_weight, i|
          stddev_weights[i] = stddev_weights_mean if stddev_weights[i].nan?
        end
      end


      if @special_case_small_variances
        if small_variance_points.length >= small_variances_limit
          #puts 'small_variances: ' + small_variance_points.to_s
          stddev_weights.each_with_index do |stddev_weight, i|
            stddev_weights[i] = 0.0 unless small_variance_points.include? i
          end
        end
      end

    end



    if @special_case_one_antenna
      if tag_answers_counts[0] == 1
        @algorithms.values.each_with_index do |algorithm, i|
          if algorithm.trainable
            stddev_weights[i] = 0.0
          else
            stddev_weights[i] = 1.0 if stddev_weights[i].nil?
          end
        end
      end
    end

    puts stddev_weights.to_s

    stddev_weights
  end






  #def create_stddev_weight(algorithm, sum_of_inverted_variances, variance, answers_count, height_index)
  #  #max_stddev = 50.0
  #
  #  tags_with_that_answers_count = algorithm.setup[height_index][:lengths][answers_count].to_i
  #  if sum_of_inverted_variances.present? and tags_with_that_answers_count > 5
  #    stddev_weight = (1.0 / variance) / sum_of_inverted_variances
  #
  #    #stddev_weight =
  #    #    [(max_stddev - stddevs_for_that_answers_count[:total]), 0.0].max / max_stddev
  #  else
  #    stddev_weight = 1.0
  #  end
  #
  #  stddev_weight
  #end

end