class AlgorithmRunner
  READER_POWERS = (20..20)
  HEIGHTS = [41, 69, 98, 116]
  FREQUENCY = 'multi'

  attr_reader :algorithms, :tags_reads_by_antennae_count


  def initialize
    parse_measurement_information
  end



  def run_algorithms
    @algorithms = {}
    rss_table = {}
    height = HEIGHTS.first

    #READER_POWERS.each do |reader_power|
    #  rss_table[reader_power] = Parser.parse(HEIGHTS.first, reader_power, FREQUENCY)
    #
    #  algorithms['wknn_rr_' + reader_power.to_s] =
    #      Algorithm::Knn.new(@measurement_information[reader_power][height]).
    #          set_settings(:rr, 10, true, rss_table[reader_power]).output
    #  algorithms['wknn_rss_' + reader_power.to_s] =
    #      Algorithm::Knn.new(@measurement_information[reader_power][height]).
    #          set_settings(:rss, 10, true, rss_table[reader_power]).output
    #end


    step = 100
    @algorithms['tri_mp'] = Algorithm::TrilaterationMaxProbability.
        new(@measurement_information[20][height]).set_settings(step).output
    @algorithms['tri_ls'] = Algorithm::TrilaterationLeastSquares.
        new(@measurement_information[20][height]).set_settings(step).output


    #algorithms['zonal_rectangles'] =
    #    Algorithm::Zonal.new(@measurement_information[20][height]).
    #    set_settings(120, 80, :average, :rectangles).output
    #
    #
    #algorithms['combo'] =
    #    Algorithm::Combinational.new(@measurement_information[20][height]).
    #        set_settings([algorithms['tri_ls'].map, algorithms['zonal_rectangles'].map]
    #    ).output
  end



  def calc_tags_reads_by_antennae_count
    @tags_reads_by_antennae_count = {}

    (1..16).each do |antennae_count|
      READER_POWERS.each do |reader_power|
        algorithm = algorithms.values.first
        tags = algorithm.tags.values
        @tags_reads_by_antennae_count[reader_power] ||= {}
        @tags_reads_by_antennae_count[reader_power][antennae_count] = tags.select{ |tag| tag.answers_count == antennae_count}.size
      end
    end

    @tags_reads_by_antennae_count
  end




  def calc_best_matches_distribution
    TagInput.tag_ids.each do |tag_id|
      antennae_count_tag_answered_to = find_algorithms_with_tag(tag_id).map[tag_id][:answers_count]
      answers_for_antennae_count = @tags_reads_by_antennae_count.values.first[antennae_count_tag_answered_to]

      errors_for_algorithms = {}
      @algorithms.select{|name,a| a.compare_by_antennae}.each do |algorithm_name, algorithm|
        errors_for_algorithms[algorithm_name] = algorithm.map[tag_id][:error] unless algorithm.map[tag_id].nil?
        algorithm.best_suited_for[antennae_count_tag_answered_to][:total] = answers_for_antennae_count
      end

      min_error = errors_for_algorithms.values.min
      algorithms_with_min_mean_error = @algorithms.select{|n,a| a.map[tag_id][:error] == min_error}

      algorithms_with_min_mean_error.each do |name, algorithm|
        algorithm.best_suited_for[antennae_count_tag_answered_to][:percent] +=
            1.0 / algorithm.best_suited_for[antennae_count_tag_answered_to][:total]
        algorithm.best_suited_for[:all][:percent] += 1.0 / algorithm.best_suited_for[:all][:total]
      end
    end
  end








  private


  def parse_measurement_information
    work_zone = WorkZone.new
    @measurement_information = {}
    READER_POWERS.each do |reader_power|
      @measurement_information[reader_power] ||= {}
      HEIGHTS.each do |height|
        TagInput # hack for preloading TagInput model before calling a cache
        cache_name = "parse_data_" + height.to_s + reader_power.to_s + FREQUENCY.to_s
        @measurement_information[reader_power][height] = {
          :work_zone => work_zone,
          :tags => Rails.cache.fetch(cache_name, :expires_in => 2.hours) do
            Parser.parse(height, reader_power, FREQUENCY)
          end
        }
      end
    end
  end


  def find_algorithms_with_tag(tag_id)
    @algorithms.each do |algorithm_name, algorithm|
      return algorithm unless algorithm.map[tag_id].nil?
    end
    0
  end

end
