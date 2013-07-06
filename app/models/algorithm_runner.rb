class AlgorithmRunner
  attr_reader :algorithms, :measurement_information


  def initialize
    @measurement_information = MeasurementInformation::Base.parse
  end





  def run_algorithms
    @algorithms = {}
    rss_table = {}
    height = MeasurementInformation::Base::HEIGHTS[0]

    step = 10

    (20..24).each do |reader_power|
      rss_table[reader_power] = Parser.parse(
          MeasurementInformation::Base::HEIGHTS.last,
          reader_power,
          MeasurementInformation::Base::FREQUENCY
      )

      #@algorithms['wknn_rss_mp_' + reader_power.to_s] =
      #    Algorithm::Knn.new(@measurement_information[reader_power][height]).
      #    set_settings(Optimization::MaximumProbability, :rss, 10, true, rss_table[reader_power]).output
      #@algorithms['wknn_rss_ls_' + reader_power.to_s] =
      #    Algorithm::Knn.new(@measurement_information[reader_power][height]).
      #    set_settings(Optimization::LeastSquares, :rss, 10, true, rss_table[reader_power]).output
      #@algorithms['wknn_rss_js_' + reader_power.to_s] =
      #    Algorithm::Knn.new(@measurement_information[reader_power][height]).
      #    set_settings(Optimization::JamesStein, :rss, 10, true, rss_table[reader_power]).output



      #@algorithms['svm_rss_' + reader_power.to_s] =
      #    Algorithm::Svm.new(@measurement_information[reader_power][height]).
      #    set_settings(:rss, rss_table[reader_power]).output

      #@algorithms['svm_rr_' + reader_power.to_s] =
      #    Algorithm::Svm.new(@measurement_information[reader_power][height]).
      #    set_settings(:rr, rss_table[reader_power]).output

      #@algorithms['zonal_'+reader_power.to_s] =
      #    Algorithm::Zonal.new(@measurement_information[reader_power][height]).
      #    set_settings(120, 80, :adaptive).output



      #@algorithms['tri_mp_rr_'+reader_power.to_s] =
      #    Algorithm::Trilateration.new(@measurement_information[reader_power][height]).
      #    set_settings(Optimization::MaximumProbability, :rr, step).output
      #@algorithms['tri_ls_rr_'+reader_power.to_s] =
      #    Algorithm::Trilateration.new(@measurement_information[reader_power][height]).
      #    set_settings(Optimization::LeastSquares, :rr, step).output
      #@algorithms['tri_js_rr_'+reader_power.to_s] =
      #    Algorithm::Trilateration.new(@measurement_information[reader_power][height]).
      #    set_settings(Optimization::JamesStein, :rr, step).output

      #@algorithms['tri_mp_rss_'+reader_power.to_s] =
      #    Algorithm::Trilateration.new(@measurement_information[reader_power][height]).
      #    set_settings(Optimization::MaximumProbability, :rss, step).output
      #@algorithms['tri_js_rss_'+reader_power.to_s] =
      #    Algorithm::Trilateration.new(@measurement_information[reader_power][height]).
      #    set_settings(Optimization::JamesStein, :rss, step).output

      %w(new old).each do |type|
        @algorithms['tri_ls_rss_'+reader_power.to_s+'_'+type] =
            Algorithm::Trilateration.new(@measurement_information[reader_power][height]).
            set_settings(Optimization::LeastSquares, :rss, step, type).output
        @algorithms['tri_ls_rr_'+reader_power.to_s+'_'+type] =
            Algorithm::Trilateration.new(@measurement_information[reader_power][height]).
            set_settings(Optimization::LeastSquares, :rr, step, type).output
      end

    end




    #@algorithms['tri_mp'] = Algorithm::Trilateration.new(@measurement_information[20][height]).
    #    set_settings(Optimization::LeastSquares, :rss, step).output

    #@algorithms['tri_ls'] = Algorithm::Trilateration.new(@measurement_information[20][height]).
    #    set_settings(Optimization::MaximumProbability, :rss, step).output





    #@algorithms['wknn_mp_rss'] =
    #    Algorithm::Knn.new(@measurement_information[20][height]).
    #    set_settings(Optimization::MaximumProbability, :rss, 10, true).output
    #@algorithms['wknn_mp_rr'] =
    #    Algorithm::Knn.new(@measurement_information[20][height]).
    #    set_settings(Optimization::MaximumProbability, :rr, 10, true).output
    #
    #@algorithms['wknn_ls_rss'] =
    #    Algorithm::Knn.new(@measurement_information[20][height]).
    #    set_settings(Optimization::LeastSquares, :rss, 10, true).output
    #@algorithms['wknn_ls_rr'] =
    #    Algorithm::Knn.new(@measurement_information[20][height]).
    #    set_settings(Optimization::LeastSquares, :rr, 10, true).output



    #
    #
    #algorithms['combo'] =
    #    Algorithm::Combinational.new(@measurement_information[20][height]).
    #        set_settings([algorithms['tri_ls'].map, algorithms['zonal_rectangles'].map]
    #    ).output


    calc_tags_best_matches_for

    @algorithms
  end




  def calc_tags_reads_by_antennae_count
    tags_reads_by_antennae_count = {}

    (1..16).each do |antennae_count|
      MeasurementInformation::Base::READER_POWERS.each do |reader_power|
        any_algorithm_with_this_power = algorithms.select{|n,a|a.reader_power == reader_power}.values.first
        if any_algorithm_with_this_power.present?
          tags = any_algorithm_with_this_power.tags.values
          tags_reads_by_antennae_count[reader_power] ||= {}
          tags_reads_by_antennae_count[reader_power][antennae_count] = tags.select do |tag|
            tag.answers_count == antennae_count
          end.size
        end
      end
    end

    tags_reads_by_antennae_count
  end



  def calc_antennae_coefficients
    coefficients_finder = AntennaeCoefficientsFinder.new(@measurement_information, @algorithms)
    {
        :by_mi => coefficients_finder.coefficients_by_mi,
        :by_algorithms => coefficients_finder.coefficients_by_algorithms
    }
  end







  private



  def calc_tags_best_matches_for
    TagInput.tag_ids.each do |tag_id|
      min_error = @algorithms.values.map{|a| a.map[tag_id][:error]}.min
      algorithms_with_min_error = @algorithms.select{|name, a| a.map[tag_id][:error] == min_error}

      algorithms_with_min_error.each do |name, algorithm|
        antennae_to_which_tag_answered = algorithm.map[tag_id][:answers_count]
        algorithm.best_suited_for[:all] += 1.0
        algorithm.best_suited_for[antennae_to_which_tag_answered] += 1.0
      end
    end
  end




end
