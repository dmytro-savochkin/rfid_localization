class AlgorithmRunner
  attr_reader :algorithms, :measurement_information


  def initialize
    @measurement_information = MeasurementInformation::Base.parse
  end








  def run_point_based_algorithms
    @algorithms = {}
    rss_table = {}
    height = MeasurementInformation::Base::HEIGHTS[0]

    algorithms_to_combine = []

    (20..20).each do |reader_power|
      training_height = MeasurementInformation::Base::HEIGHTS.last
      rss_table[reader_power] = MeasurementInformation::Base.parse_specific_tags_data(training_height, reader_power)
      puts reader_power.to_s

      puts 'least_squares'
      @algorithms['wknn_rss_ls_' + reader_power.to_s] =
          Algorithm::PointBased::Knn.new(@measurement_information[reader_power][height]).
          set_settings(Optimization::LeastSquares, :rss, 10, true, rss_table[reader_power]).output
      puts 'max_prob'
      @algorithms['wknn_rss_mp_' + reader_power.to_s] =
          Algorithm::PointBased::Knn.new(@measurement_information[reader_power][height]).
          set_settings(Optimization::MaximumProbability, :rss, 10, true, rss_table[reader_power]).output
      puts 'cosine'
      @algorithms['wknn_rss_cs_' + reader_power.to_s] =
          Algorithm::PointBased::Knn.new(@measurement_information[reader_power][height]).
          set_settings(Optimization::CosineMaximumProbability, :rss, 10, true, rss_table[reader_power]).output



      @algorithms['neural_fann_rss_16' + reader_power.to_s] =
          Algorithm::PointBased::Neural::FeedForward::Fann.new(@measurement_information[reader_power][height]).
          set_settings(:rss, rss_table[reader_power], 16).output




      @algorithms['zonal_'+reader_power.to_s] =
          Algorithm::PointBased::Zonal.new(@measurement_information[reader_power][height]).
          set_settings(:adaptive).output
      #@algorithms['zonal_average_'+reader_power.to_s] =
      #    Algorithm::Zonal.new(@measurement_information[reader_power][height]).
      #    set_settings(:average).output


      #@algorithms['tri_ls_rss_'+reader_power.to_s] =
      #    Algorithm::PointBased::Trilateration.new(@measurement_information[reader_power][height]).
      #    set_settings(Optimization::LeastSquares, :rss).output
      #
      #@algorithms['tri_mp_rss_'+reader_power.to_s] =
      #    Algorithm::PointBased::Trilateration.new(@measurement_information[reader_power][height]).
      #    set_settings(Optimization::MaximumProbability, :rss).output



      #%w(new).each do |regression_type|
      #  #@algorithms['tri_ls_rss_'+reader_power.to_s+'_'+type] =
      #  #    Algorithm::Trilateration.new(@measurement_information[reader_power][height]).
      #  #    set_settings(Optimization::LeastSquares, :rss, step, type).output
      #  @algorithms['tri_ls_rss_'+reader_power.to_s+'_'+regression_type] =
      #      Algorithm::Trilateration.new(@measurement_information[reader_power][height]).
      #      set_settings(Optimization::LeastSquares, :rss, step, regression_type).output
      #end
    end


    #%w(new old).each do |type|
    #  @algorithms['tri_ls_rr_sum_'+type] =
    #      Algorithm::Trilateration.new(@measurement_information[:sum][height]).
    #      set_settings(Optimization::LeastSquares, :rr, step, type).output
    #end


    #algorithms['combo'] =
    #    Algorithm::Combinational.new(@measurement_information[20][height]).
    #    set_settings(@algorithms.map{|k,a|a.map}).output


    calc_tags_best_matches_for

    @algorithms
  end
















  def run_classifiers_algorithms
    @algorithms = {}
    tags_input = {}
    height = MeasurementInformation::Base::HEIGHTS[2]



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


    #classifiers_types = [:svm, :neural, :hyperpipes, :bayes_network, :bayes, :ib1]
    #classifiers_types = [:svm]
    classifiers_types = [:svm, :neural, :hyperpipes, :bayes, :ib1]
    classifiers_container = {}

    (20..25).each do |reader_power|
      puts reader_power
      tags_input[reader_power] = get_tags_input(reader_power)

      [:rss, :rr].each do |type|
        classifiers_types.each do |classifier_class|
          klass = ('Algorithm::Classifier::' + classifier_class.to_s.camelize).constantize
          classifier_string = classifier_class.to_s
          classifier_name = classifier_string + '_' + type.to_s + '_' + reader_power.to_s

          @algorithms[classifier_name] =
              klass.new(@measurement_information[reader_power][height]).
              set_settings(type, tags_input[reader_power]).output
          classifiers_container[classifier_class] ||= {}
          classifiers_container[classifier_class][classifier_name] =
              @algorithms[classifier_string + '_' + type.to_s + '_' + reader_power.to_s]
        end
      end
    end











    #classifiers_types.each do |classifier_type|
    #  @algorithms[classifier_type.to_s + '_combo'] =
    #      Algorithm::Classifier::Combinational.new(@measurement_information[25][height]).
    #      set_settings(
    #          one_type_classifiers_hash( classifiers_container[classifier_type] )
    #      ).output
    #end



    #combinations.each do |combination|
    #  @algorithms[combination.map(&:to_s).join('_')] =
    #      Algorithm::Classifier::Combinational.new(@measurement_information[25][height]).
    #      set_settings(
    #          Hash[ *combination.map{|e| one_type_classifiers_hash(classifiers_container[e]).to_a }.flatten(2) ]
    #      ).output
    #end



    puts 'voting'
    @algorithms['voter'] =
        Algorithm::Classifier::Meta::Voter.new(@measurement_information[25][height]).
        set_settings(
            full_classifiers_hash(classifiers_container)
        ).output

    puts 'combining'
    @algorithms['knn_combiner'] =
        Algorithm::Classifier::Meta::KnnCombiner.new(@measurement_information[25][height]).
        set_settings(
            full_classifiers_hash(classifiers_container)
        ).output

    puts 'uppering bound'
    @algorithms['upper_bound'] =
        Algorithm::Classifier::Meta::UpperBound.new(@measurement_information[25][height]).
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
          tags = any_algorithm_with_this_power.tags_test_input.values
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


  def get_tags_input(reader_power)
    tags_input = []
    MeasurementInformation::Base::HEIGHTS.each do |height|
      tags_input.push Parser.parse(height, reader_power, MeasurementInformation::Base::FREQUENCY)
    end
    tags_input
  end



  def one_type_classifiers_hash(classifiers_container)
    Hash[classifiers_container.map {|k,v| [k, {classification_success: v.classification_success, map: v.map}]}]
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
