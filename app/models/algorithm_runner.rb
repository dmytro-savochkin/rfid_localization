class AlgorithmRunner
  attr_reader :algorithms, :measurement_information


  def initialize
    @measurement_information = MI::Base.parse
  end








  def run_point_based_algorithms
    @algorithms = {}
    tags_input = {}

    algorithms_to_combine = []

    (21..21).each do |reader_power|
      puts reader_power.to_s

      tags_input[reader_power] = get_tags_input(reader_power)

      [:rss, :rr].each do |mi_type|
        @algorithms['wknn_ls_' + mi_type.to_s + '_' + reader_power.to_s] =
            Algorithm::PointBased::Knn.new(@measurement_information[reader_power], tags_input[reader_power]).
            set_settings(mi_type, Optimization::LeastSquares, 10, true).output

        #@algorithms['neural_fann_64' + mi_type.to_s + '_' + reader_power.to_s] =
        #    Algorithm::PointBased::Neural.new(@measurement_information[reader_power], tags_input[reader_power]).
        #    set_settings(mi_type, 250).output




        #['2.0_2.0', 'circular', 'one'].each do |model_type|
        ['2.0_2.0'].each do |model_type|
          #[:average, :specific].each do |antenna_type|
          [:average].each do |antenna_type|
            [Optimization::WeightedLeastSquares].each do |klass|
            #[Optimization::WeightedLeastSquares].each do |klass|
              @algorithms['tri_' + antenna_type.to_s + '_' + klass.to_s.gsub(/[^\w]/, '') + '_' + mi_type.to_s + '_' + reader_power.to_s + '_' + model_type.to_s] =
                  Algorithm::PointBased::Trilateration.new(@measurement_information[reader_power], tags_input[reader_power]).
                  set_settings(mi_type, klass, antenna_type, model_type).output
            end
          end
        end
      end


      @algorithms['zonal_70_' + reader_power.to_s] =
          Algorithm::PointBased::Zonal.new(@measurement_information[reader_power], tags_input[reader_power]).
          set_settings(:ellipses, :rss, -70.0).output
      @algorithms['zonal_71_' + reader_power.to_s] =
          Algorithm::PointBased::Zonal.new(@measurement_information[reader_power], tags_input[reader_power]).
          set_settings(:ellipses, :rss, -71.0).output

      @algorithms['tri_mp_rss_'+reader_power.to_s] =
          Algorithm::PointBased::Trilateration.new(@measurement_information[reader_power], tags_input[reader_power]).
          set_settings(Optimization::WeightedLeastSquares, :rss).output




      ## variant for patents
      #@algorithms['zonal_70_' + reader_power.to_s] =
      #    Algorithm::PointBased::Zonal.new(@measurement_information[reader_power], tags_input[reader_power], false).
      #    set_settings(:ellipses, :rss, -71.0).output
      #@algorithms['tri_' + '_rr_' + reader_power.to_s] =
      #    Algorithm::PointBased::Trilateration.new(@measurement_information[reader_power], tags_input[reader_power], false).
      #    set_settings(:rss, Optimization::LeastSquares, :average, 'circular').output
      #@algorithms['knn_rss_' + reader_power.to_s] =
      #      Algorithm::PointBased::Knn.new(@measurement_information[reader_power], tags_input[reader_power], false).
      #      set_settings(:rss, Optimization::MaximumProbability, 2, false).output
      #@algorithms['patent_comb_' + reader_power.to_s] =
      #    Algorithm::PointBased::Probabilistic::Combiner.new(@measurement_information[reader_power], tags_input[reader_power], false).
      #    set_settings(PointStepper.new(5), true).output
      #@algorithms['patent_comb_' + reader_power.to_s + 'no_weighting'] =
      #    Algorithm::PointBased::Probabilistic::Combiner.new(@measurement_information[reader_power], tags_input[reader_power], false).
      #    set_settings(PointStepper.new(5), false).output




      #%w(new).each do |regression_type|
      #  #@algorithms['tri_ls_rss_'+reader_power.to_s+'_'+type] =
      #  #    Algorithm::Trilateration.new(@measurement_information[reader_power][height]).
      #  #    set_settings(Optimization::LeastSquares, :rss, step, type).output
      #  @algorithms['tri_ls_rss_'+reader_power.to_s+'_'+regression_type] =
      #      Algorithm::Trilateration.new(@measurement_information[reader_power][height]).
      #      set_settings(Optimization::LeastSquares, :rss, step, regression_type).output
      #end
    end




    #algorithms['combo'] =
    #    Algorithm::Combinational.new(@measurement_information[20][height]).
    #    set_settings(@algorithms.map{|k,a|a.map}).output


    #calc_tags_best_matches_for

    @algorithms
  end


  def trilateration_map
    reader_power = 20
    tags_input = get_tags_input(reader_power)
    Algorithm::PointBased::Trilateration.new(@measurement_information[reader_power], tags_input).
        set_settings(:rss, Optimization::WeightedLeastSquares, :average, '2.0_2.0').
        get_decision_function
  end


















  #combinations = [
  #    [:svm, :ib1],
  #    [:svm, :neural],
  #    [:svm, :naive_bayes],
  #    [:ib1, :neural],
  #    [:ib1, :naive_bayes],
  #    [:neural, :naive_bayes],
  #    [:ib1, :neural, :svm],
  #    [:ib1, :neural, :naive_bayes],
  #    [:ib1, :neural, :svm, :naive_bayes],
  #    [:ib1, :neural, :svm, :naive_bayes, :hyperpipes]
  #]




  def run_classifiers_algorithms
    @algorithms = {}
    tags_input = {}

    combinations = [
        [:svm, :neural],
        [:ib1, :neural],
        [:neural, :naive_bayes],
        [:ib1, :neural, :svm],
        [:ib1, :neural, :naive_bayes],
        [:ib1, :neural, :svm, :naive_bayes],
        [:ib1, :neural, :svm, :naive_bayes, :hyperpipes],
        [:ib1, :neural, :svm, :naive_bayes, :hyperpipes, :random_forest, :adaboost]
    ]


    classifiers_types = [:svm, :neural, :hyperpipes, :naive_bayes, :ib1, :random_forest, :adaboost]
    #classifiers_types = [:neural]
    classifiers_container = {}

    (20..25).each do |reader_power|
      puts ''
      puts reader_power
      tags_input[reader_power] = get_tags_input(reader_power)

      current_power_classifiers_container = {}

      [:rr].each do |type|
        puts ''
        puts type.to_s
        classifiers_types.each do |classifier_class|
          puts classifier_class.to_s
          klass = ('Algorithm::Classifier::' + classifier_class.to_s.camelize).constantize
          classifier_string = classifier_class.to_s
          classifier_name = classifier_string + '_' + type.to_s + '_' + reader_power.to_s

          algorithm = klass.new(@measurement_information[reader_power], tags_input[reader_power]).
              set_settings(type).output
          @algorithms[classifier_name] = algorithm
          classifiers_container[classifier_class] ||= {}
          current_power_classifiers_container[classifier_class] ||= {}
          classifiers_container[classifier_class][classifier_name] = algorithm
          current_power_classifiers_container[classifier_class][classifier_name] = algorithm
        end
      end


      if reader_power >= 25



        #combinations.each do |combination|
        #  puts ''
        #  puts combination.map(&:to_s).join('_') + ' ' + reader_power.to_s
        #  data = Hash[ *combination.map{|e| one_type_classifiers_hash(current_power_classifiers_container[e]).to_a }.flatten(2) ]
        #  name = combination.map(&:to_s).join('_') + '_' + reader_power.to_s
        #  @algorithms[name] =
        #      Algorithm::Classifier::Meta::Voter.new(data).set_settings().output
        #  @algorithms[name + 'knn'] =
        #      Algorithm::Classifier::Meta::Knn.new(data).set_settings(true).output
        #  @algorithms[name + '050'] =
        #      Algorithm::Classifier::Meta::KnnVoter.new(data).set_settings(0.5).output
        #end



        classifiers_types.each do |classifier_type|
          puts classifier_type.to_s + '_combo'
          @algorithms[classifier_type.to_s + '_combo_knn0.5' + reader_power.to_s] =
              Algorithm::Classifier::Meta::KnnVoter.new(
                  one_type_classifiers_hash( classifiers_container[classifier_type] )
              ).set_settings(0.5).output
        end




        puts ''
        combinations.each do |combination|
          puts combination.map(&:to_s).join('_') + ' diapasone ' + reader_power.to_s
          data = Hash[ *combination.map{|e| one_type_classifiers_hash(classifiers_container[e]).to_a }.flatten(2) ]
          name = combination.map(&:to_s).join('_') + '_diap_to_' + reader_power.to_s
          @algorithms[name] =
              Algorithm::Classifier::Meta::KnnVoter.new(data).set_settings(0.5).output
        end









        #puts 'meta-meta combining'
        #algorithms_to_combine = {}
        #classifiers_types.each do |classifier_type|
        #  name = classifier_type.to_s + '_combo_knn0.5' + reader_power.to_s
        #  algorithms_to_combine[classifier_type] = @algorithms[name]
        #end
        #@algorithms['meta_' + reader_power.to_s] =
        #    Algorithm::Classifier::Meta::KnnVoter.new(
        #        one_type_classifiers_hash( algorithms_to_combine )
        #    ).set_settings(0.5).output

      end

      #puts 'uppering bound'
      #@algorithms['upper_bound_' + reader_power.to_s] =
      #    Algorithm::Classifier::Meta::UpperBound.new(
      #        full_classifiers_hash(classifiers_container)
      #    ).set_settings().output

    end



    #combinations.each do |combination|
    #  puts combination.map(&:to_s).join('_')
    #  data = Hash[ *combination.map{|e| one_type_classifiers_hash(current_power_classifiers_container[e]).to_a }.flatten(2) ]
    #
    #  @algorithms[combination.map(&:to_s).join('_') + '_' + reader_power.to_s] =
    #      Algorithm::Classifier::Meta::Voter.new(
    #          Hash[ *one_type_classifiers_hash(current_power_container).to_a ]
    #      ).set_settings().output
    #  @algorithms[combination.map(&:to_s).join('_') + 'knn' + '_' + reader_power.to_s] =
    #      Algorithm::Classifier::Meta::Knn.new(
    #          Hash[ *combination.map{|e| one_type_classifiers_hash(classifiers_container[e]).to_a }.flatten(2) ]
    #      ).set_settings(true).output
    #  @algorithms[combination.map(&:to_s).join('_') + '050' + '_' + reader_power.to_s] =
    #      Algorithm::Classifier::Meta::KnnVoter.new(
    #          Hash[ *combination.map{|e| one_type_classifiers_hash(classifiers_container[e]).to_a }.flatten(2) ]
    #      ).set_settings(0.5).output
    #end










    #puts 'meta-meta combining'
    #%w(combo_vote combo_knn combo_knn0.5).each do |combo_type|
    #
    #  algorithms_to_combine = {}
    #  classifiers_types.each do |classifier_type|
    #    name = classifier_type.to_s + '_' + combo_type
    #    algorithms_to_combine[classifier_type] = @algorithms[name]
    #  end
    #
    #  @algorithms['meta-meta_' + combo_type +'_knn0.5'] =
    #      Algorithm::Classifier::Meta::KnnVoter.new(
    #          one_type_classifiers_hash( algorithms_to_combine )
    #      ).set_settings(0.5).output
    #end
    #
    #
    #puts 'voting'
    #@algorithms['voter'] =
    #    Algorithm::Classifier::Meta::Voter.new(
    #        full_classifiers_hash(classifiers_container)
    #    ).set_settings().output
    #[0.5].each do |threshold|
    #  puts 'combining ' + threshold.to_s
    #  @algorithms['knn_combiner' + threshold.to_s] =
    #      Algorithm::Classifier::Meta::KnnVoter.new(
    #          full_classifiers_hash(classifiers_container)
    #      ).set_settings(threshold).output
    #end
    #
    #puts 'combining'
    #@algorithms['knn_combiner'] =
    #    Algorithm::Classifier::Meta::Knn.new(
    #        full_classifiers_hash(classifiers_container)
    #    ).set_settings(true).output
    #
    #puts 'combining all table'
    #@algorithms['knn_combiner_all_table'] =
    #    Algorithm::Classifier::Meta::Knn.new(
    #        full_classifiers_hash(classifiers_container)
    #    ).set_settings(false).output
    #
    #puts 'uppering bound'
    #@algorithms['upper_bound'] =
    #    Algorithm::Classifier::Meta::UpperBound.new(
    #        full_classifiers_hash(classifiers_container)
    #    ).set_settings().output





    #calc_tags_best_matches_for

    @algorithms
  end












  def calc_tags_reads_by_antennae_count
    tags_reads_by_antennae_count = {}

    (1..16).each do |antennae_count|
      MI::Base::READER_POWERS.each do |reader_power|
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
    MI::Base::HEIGHTS.each do |height|
      tags_input.push Parser.parse(height, reader_power, MI::Base::FREQUENCY)
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
