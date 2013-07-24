class AlgorithmRunner
  attr_reader :algorithms, :measurement_information


  def initialize
    @measurement_information = MeasurementInformation::Base.parse
  end








  def run_algorithms
    @algorithms = {}
    rss_table = {}
    height = MeasurementInformation::Base::HEIGHTS[0]

    algorithms_to_combine = []

    step = 10


    (20..23).each do |reader_power|
      training_height = MeasurementInformation::Base::HEIGHTS.last
      rss_table[reader_power] = MeasurementInformation::Base.parse_specific_tags_data(training_height, reader_power)
      puts reader_power.to_s

      puts 'least_squares'
      @algorithms['wknn_rss_ls_' + reader_power.to_s] =
          Algorithm::Knn.new(@measurement_information[reader_power][height]).
          set_settings(Optimization::LeastSquares, :rss, 10, true, rss_table[reader_power]).output
      puts 'max_prob'
      @algorithms['wknn_rss_mp_' + reader_power.to_s] =
          Algorithm::Knn.new(@measurement_information[reader_power][height]).
          set_settings(Optimization::MaximumProbability, :rss, 10, true, rss_table[reader_power]).output
      puts 'cosine'
      @algorithms['wknn_rss_cs_' + reader_power.to_s] =
          Algorithm::Knn.new(@measurement_information[reader_power][height]).
          set_settings(Optimization::CosineMaximumProbability, :rss, 10, true, rss_table[reader_power]).output





      #@algorithms['wknn_rss_ls_' + reader_power.to_s] =
      #    Algorithm::Knn.new(@measurement_information[reader_power][height]).
      #    set_settings(Optimization::MaximumProbability, :rss, 10, true, rss_table[reader_power]).output
      #algorithms_to_combine.push @algorithms['wknn_rss_ls_' + reader_power.to_s].map


      #puts 'fann8'
      #@algorithms['neural_fann_rss_8' + reader_power.to_s] =
      #    Algorithm::Neural::FeedForward::Fann.new(@measurement_information[reader_power][height]).
      #    set_settings(:rss, rss_table[reader_power], 8).output
      #
      #
      #puts 'fann16'
      #@algorithms['neural_fann_rss_16' + reader_power.to_s] =
      #    Algorithm::Neural::FeedForward::Fann.new(@measurement_information[reader_power][height]).
      #    set_settings(:rss, rss_table[reader_power], 16).output
      #
      #puts 'fann32'
      #@algorithms['neural_fann_rss_32' + reader_power.to_s] =
      #    Algorithm::Neural::FeedForward::Fann.new(@measurement_information[reader_power][height]).
      #    set_settings(:rss, rss_table[reader_power], 32).output



      #@algorithms['neural_ai4r_rss_' + reader_power.to_s] =
      #    Algorithm::Neural::FeedForward::Ai4r.new(@measurement_information[reader_power][height]).
      #    set_settings(:rss, rss_table[reader_power]).output

      #@algorithms['neural_fann_total_' + reader_power.to_s] =
      #    Algorithm::Neural::FeedForward::FannTotal.new(@measurement_information[reader_power][height]).
      #    set_settings(rss_table[reader_power]).output

      #@algorithms['svm_rr_' + reader_power.to_s] =
      #    Algorithm::Classifier::Svm.new(@measurement_information[reader_power][height]).
      #    set_settings(:rr, rss_table[reader_power]).output






      @algorithms['zonal_'+reader_power.to_s] =
          Algorithm::Zonal.new(@measurement_information[reader_power][height]).
          set_settings(:adaptive).output
      #@algorithms['zonal_average_'+reader_power.to_s] =
      #    Algorithm::Zonal.new(@measurement_information[reader_power][height]).
      #    set_settings(:average).output


      #puts 'cosine'
      #@algorithms['tri_cs_rss_'+reader_power.to_s] =
      #    Algorithm::Trilateration2.new(@measurement_information[reader_power][height]).
      #    set_settings(Optimization::CosineMaximumProbability, :rss, step, regression_type).output
      #puts 'mp'
      #@algorithms['tri_mp_rss_'+reader_power.to_s] =
      #    Algorithm::Trilateration2.new(@measurement_information[reader_power][height]).
      #    set_settings(Optimization::MaximumProbability, :rss, step, regression_type).output
      #puts 'ls'


      @algorithms['tri_ls_rss_'+reader_power.to_s] =
          Algorithm::Trilateration.new(@measurement_information[reader_power][height]).
          set_settings(Optimization::LeastSquares, :rss, step).output

      @algorithms['tri_mp_rss_'+reader_power.to_s] =
          Algorithm::Trilateration.new(@measurement_information[reader_power][height]).
          set_settings(Optimization::MaximumProbability, :rss, step).output


      #@algorithms['tri_js_rss_'+reader_power.to_s] =
      #    Algorithm::Trilateration.new(@measurement_information[reader_power][height]).
      #    set_settings(Optimization::JamesStein, :rss, step).output

      #@algorithms['tri_mp_rss_'+reader_power.to_s] =
      #    Algorithm::Trilateration.new(@measurement_information[reader_power][height]).
      #    set_settings(Optimization::MaximumProbability, :rss, step).output
      #@algorithms['tri_js_rss_'+reader_power.to_s] =
      #    Algorithm::Trilateration.new(@measurement_information[reader_power][height]).
      #    set_settings(Optimization::JamesStein, :rss, step).output


      #%w(new).each do |regression_type|
      #  #@algorithms['tri_ls_rss_'+reader_power.to_s+'_'+type] =
      #  #    Algorithm::Trilateration.new(@measurement_information[reader_power][height]).
      #  #    set_settings(Optimization::LeastSquares, :rss, step, type).output
      #  @algorithms['tri_ls_rss_'+reader_power.to_s+'_'+regression_type] =
      #      Algorithm::Trilateration.new(@measurement_information[reader_power][height]).
      #      set_settings(Optimization::LeastSquares, :rss, step, regression_type).output
      #end
    end


    #@algorithms['svm_rss_20'] =
    #    Algorithm::Classifier::Svm.new(@measurement_information[20][height]).
    #    set_settings(:rss, rss_table[20]).output
    #algorithms_to_combine.push @algorithms['svm_rss_20'].map
    #@algorithms['svm_rr_20'] =
    #    Algorithm::Classifier::Svm.new(@measurement_information[20][height]).
    #    set_settings(:rr, rss_table[20]).output
    #algorithms_to_combine.push @algorithms['svm_rr_20'].map


    #%w(new old).each do |type|
    #  @algorithms['tri_ls_rr_sum_'+type] =
    #      Algorithm::Trilateration.new(@measurement_information[:sum][height]).
    #      set_settings(Optimization::LeastSquares, :rr, step, type).output
    #end



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
    #    Algorithm::Knn.new(@measurement_information[:sum][height]).
    #    set_settings(Optimization::LeastSquares, :rr, 10, true).output





    #algorithms['combo'] =
    #    Algorithm::Combinational.new(@measurement_information[20][height]).
    #    set_settings(@algorithms.map{|k,a|a.map}).output


    calc_tags_best_matches_for

    @algorithms
  end














  def run_classifiers_algorithms
    @algorithms = {}
    rss_table = {}
    height = MeasurementInformation::Base::HEIGHTS[0]



    combinations = [
        [:svm, :neural, :hyperpipes, :bayes_network, :bayes, :ib1, :id3],
        [:svm, :neural, :hyperpipes, :bayes_network, :bayes, :ib1, :prism],
        [:svm, :neural, :hyperpipes, :bayes_network, :bayes, :ib1],

        [:svm, :neural, :hyperpipes, :bayes, :prism, :ib1, :id3],
        [:svm, :neural, :hyperpipes, :bayes, :ib1, :id3],
        [:svm, :neural, :hyperpipes, :bayes, :ib1],
        [:svm, :neural, :hyperpipes, :bayes],

        [:svm, :neural, :hyperpipes, :bayes_network, :prism, :ib1, :id3],
        [:svm, :neural, :hyperpipes, :bayes_network, :ib1, :id3],
        [:svm, :neural, :hyperpipes, :bayes_network, :ib1],
        [:svm, :neural, :hyperpipes, :bayes_network],

        [:svm, :neural, :hyperpipes, :ib1]
    ]



    classifiers_types = [:svm, :neural, :hyperpipes, :bayes_network, :bayes, :ib1, :id3, :prism]
    classifiers_container = {}

    (20..23).each do |reader_power|
      rss_table[reader_power] = Parser.parse(
          MeasurementInformation::Base::HEIGHTS.last,
          reader_power,
          MeasurementInformation::Base::FREQUENCY
      )


      [:rss, :rr].each do |type|
        classifiers_types.each do |classifier_class|
          klass = ('Algorithm::Classifier::' + classifier_class.to_s.camelize).constantize
          classifier_string = classifier_class.to_s
          classifier_name = classifier_string + '_classifier_' + type.to_s + '_' + reader_power.to_s

          @algorithms[classifier_name] =
              klass.new(@measurement_information[reader_power][height]).
                  set_settings(type, rss_table[reader_power]).output
          classifiers_container[classifier_class] ||= {}
          classifiers_container[classifier_class][classifier_name] =
              @algorithms[classifier_string + '_classifier_' + type.to_s + '_' + reader_power.to_s]

        end
      end
    end











    classifiers_types.each do |classifier_type|
      @algorithms[classifier_type.to_s + '_combo'] =
          Algorithm::Classifier::Combinational.new(@measurement_information[25][height]).
          set_settings(
              one_type_classifiers_hash( classifiers_container[classifier_type] )
          ).output
    end



    combinations.each do |combination|
      @algorithms[combination.map(&:to_s).join('_')] =
          Algorithm::Classifier::Combinational.new(@measurement_information[25][height]).
          set_settings(
              Hash[ *combination.map{|e| one_type_classifiers_hash(classifiers_container[e]).to_a }.flatten(2) ]
          ).output

    end



    @algorithms['combo'] =
        Algorithm::Classifier::Combinational.new(@measurement_information[25][height]).
        set_settings(
            full_classifiers_hash(classifiers_container)
        ).output



    @algorithms['upper_bound'] =
        Algorithm::Classifier::UpperBound.new(@measurement_information[25][height]).
        set_settings(
            full_classifiers_hash(classifiers_container)
        ).output

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



  def one_type_classifiers_hash(classifiers_container)
    Hash[classifiers_container.map {|k,v| [k, {classifying_success: v.classifying_success, map: v.map}]}]
  end


  def full_classifiers_hash(classifiers_container)
    ary = classifiers_container.values.map{ |h| one_type_classifiers_hash(h).to_a}.flatten(2)
    Hash[*ary]
  end


  def calc_tags_best_matches_for
    TagInput.tag_ids.each do |tag_id|
      min_error = @algorithms.
          values.
          reject{|a| a.map[tag_id].nil?}.
          map{|a| a.map[tag_id][:error]}.
          reject{|e|e.nil?}.
          min

      algorithms_with_min_error =
          @algorithms.reject{|n, a| a.map[tag_id].nil?}.select{|n, a| a.map[tag_id][:error] == min_error}

      algorithms_with_min_error.each do |name, algorithm|
        antennae_to_which_tag_answered = algorithm.map[tag_id][:answers_count]
        algorithm.best_suited_for[:all] += 1.0
        algorithm.best_suited_for[antennae_to_which_tag_answered] += 1.0
      end
    end
  end




end
