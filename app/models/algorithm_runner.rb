class AlgorithmRunner
  attr_reader :algorithms, :measurement_information


  def initialize
    @measurement_information = MI::Base.parse
  end








  def run_point_based_algorithms
    @algorithms = {}
    tags_input = {}
    weights = []


    #puts ' ' +
    #  @measurement_information.select{|k,v| k == 20 or k == 21 or k == 22 or k == 23 or k == 24}.
    #  values.map{|h1| h1[:tags].values.map{|h2| h2.values.map{|h3| h3.answers[:rss][:average].values}}}.flatten.min.to_s +
    #  @measurement_information.select{|k,v| k == 20 or k == 21 or k == 22 or k == 23 or k == 24}.
    #  values.map{|h1| h1[:tags].values.map{|h2| h2.values.map{|h3| h3.answers[:rss][:average].values}}}.flatten.max.to_s


    empirical_heights = :basic
    all_heights = :all





    #@algorithms['e6'] =
    #    Algorithm::PointBased::Empirical.new(@measurement_information[20], get_tags_input(20), all_heights).
    #    set_settings(:rss, Optimization::LeastSquares, :six).output




    (20..20).each do |reader_power|
      puts 'POWER:' + reader_power.to_s
      tags_input[reader_power] = get_tags_input(reader_power)

      [:rss].each do |mi_type|
        #[1.0, 1.01, 1.02, 1.03, 1.04, 1.05, 1.06, 1.07, 1.08, 1.09, 1.5].each do |ellipse_ratio|
        [1.5].each do |ellipse_ratio|
          #[0.0, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5].each do |rr_limit|
          [0.0, 0.1, 0.2, 0.3, 0.4, 0.5].each do |rr_limit|
            puts 'e'+ellipse_ratio.to_s + ' ' + rr_limit.to_s
            [:circle, :ellipse].each do |model_type|
              unless model_type == :circle and ellipse_ratio == 2.0
                [:local_maximum, :global_maximum].each do |normalization|
                  name = 'lin_tri_' + normalization.to_s + '_' + rr_limit.to_s.gsub(/\./, '') +
                      '_' + mi_type.to_s + '_' + reader_power.to_s + '_' + model_type.to_s +
                      'e' + ellipse_ratio.to_s.gsub(/\./, '')
                  @algorithms[name] =
                      Algorithm::PointBased::LinearTrilateration.new(@measurement_information[reader_power], tags_input[reader_power], empirical_heights).
                      set_settings(mi_type, Optimization::LeastSquares, model_type, rr_limit, ellipse_ratio, normalization).output
                end
              end
            end
          end
        end

        puts 'TRI NOW'

        #[1.5].each do |ellipse_ratio|
        #  [0.0, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5].each do |rr_limit|
        #  #[0.0].each do |rr_limit|
        #    puts 't'+rr_limit.to_s
        #    ['new_elliptical_watt'].each do |model_type|
        #      [:average].each do |antenna_type|
        #        @algorithms['tri_w_' + rr_limit.to_s + '_' + antenna_type.to_s + '_' + '_' + mi_type.to_s + '_' + reader_power.to_s + '_' + model_type.to_s + 'e' + ellipse_ratio.to_s] =
        #            Algorithm::PointBased::Trilateration.new(@measurement_information[reader_power], tags_input[reader_power], all_heights).
        #            set_settings(mi_type, Optimization::WeightedLeastSquares, antenna_type, model_type, rr_limit, ellipse_ratio).output
        #        @algorithms['tri_l_' + rr_limit.to_s + '_' + antenna_type.to_s + '_' + '_' + mi_type.to_s + '_' + reader_power.to_s + '_' + model_type.to_s + 'e' + ellipse_ratio.to_s] =
        #            Algorithm::PointBased::Trilateration.new(@measurement_information[reader_power], tags_input[reader_power], all_heights).
        #            set_settings(mi_type, Optimization::LeastSquares, antenna_type, model_type, rr_limit, ellipse_ratio).output
        #        #weights.push({:other => 0.4, '1' => 0.45, '2' => 0.4})
        #      end
        #    end
        #  end
        #end

      end



      #[:rss].each do |mi_type|
      #  [0.15, 0.2, 0.25, 0.3].each do |variant|
      #    @algorithms['e' + variant.to_s + '_' + mi_type.to_s + '_' + reader_power.to_s] =
      #        Algorithm::PointBased::Empirical.new(@measurement_information[reader_power], tags_input[reader_power], all_heights).
      #        set_settings(mi_type, Optimization::LeastSquares, variant).output
      #  end
      #end


      [:rss].each do |mi_type|
        #['new_circular', 'new_elliptical'].each do |model_type|

      end
    end



    puts 'xi'




    #mi[reader_power][:tags][height][tag_id].answers[:rss][:average][antenna_number]





    #[:rss].each do |mi_type|
    #  (20..24).each do |reader_power|
    #    tags_input[reader_power] = get_tags_input(reader_power)
    #
    #    @algorithms['wknn_ls_' + mi_type.to_s + '_' + reader_power.to_s] =
    #        Algorithm::PointBased::Knn.new(@measurement_information[reader_power], tags_input[reader_power], all_heights).
    #        set_settings(mi_type, Optimization::LeastSquares, 10, true).output
    #
    #    #@algorithms['neural_fann_64' + mi_type.to_s + '_' + reader_power.to_s] =
    #    #    Algorithm::PointBased::Neural.new(@measurement_information[reader_power], tags_input[reader_power]).
    #    #    set_settings(mi_type, 250).output
    #    #weights.push({:other => 0.2, '1' => 0.1, '2' => 0.2})
    #  end
    #end
    #
    #[:rr].each do |mi_type|
    #  (20..23).each do |reader_power|
    #    tags_input[reader_power] = get_tags_input(reader_power)
    #
    #    @algorithms['wknn_ls_' + mi_type.to_s + '_' + reader_power.to_s] =
    #        Algorithm::PointBased::Knn.new(@measurement_information[reader_power], tags_input[reader_power], all_heights).
    #            set_settings(mi_type, Optimization::LeastSquares, 10, true).output
    #
    #    #@algorithms['neural_fann_64' + mi_type.to_s + '_' + reader_power.to_s] =
    #    #    Algorithm::PointBased::Neural.new(@measurement_information[reader_power], tags_input[reader_power]).
    #    #    set_settings(mi_type, 250).output
    #    #weights.push({:other => 0.2, '1' => 0.1, '2' => 0.2})
    #  end
    #end



    #(20..22).each do |reader_power|
    #  puts reader_power.to_s
    #  tags_input[reader_power] = get_tags_input(reader_power)
    #
    #
    #  @algorithms['zonal_70_' + reader_power.to_s] =
    #      Algorithm::PointBased::Zonal.new(@measurement_information[reader_power], tags_input[reader_power], all_heights).
    #      set_settings(:ellipses, :rss, -70.0).output
    #
    #  #weight = {:other => 0.4, '1' => 0.45, '2' => 0.4}
    #  #weights.push(weight)
    #
    #
    #  #@algorithms['zonal_71_' + reader_power.to_s] =
    #  #    Algorithm::PointBased::Zonal.new(@measurement_information[reader_power], tags_input[reader_power], all_heights).
    #  #    set_settings(:ellipses, :rss, -71.0).output
    #  #weights.push(weight)
    #
    #
    #
    #
    #
    #  ## variant for patents
    #  #@algorithms['zonal_70_' + reader_power.to_s] =
    #  #    Algorithm::PointBased::Zonal.new(@measurement_information[reader_power], tags_input[reader_power], false).
    #  #    set_settings(:ellipses, :rss, -71.0).output
    #  #@algorithms['tri_' + '_rr_' + reader_power.to_s] =
    #  #    Algorithm::PointBased::Trilateration.new(@measurement_information[reader_power], tags_input[reader_power], false).
    #  #    set_settings(:rss, Optimization::LeastSquares, :average, 'circular').output
    #  #@algorithms['knn_rss_' + reader_power.to_s] =
    #  #      Algorithm::PointBased::Knn.new(@measurement_information[reader_power], tags_input[reader_power], false).
    #  #      set_settings(:rss, Optimization::MaximumProbability, 2, false).output
    #  #@algorithms['patent_comb_' + reader_power.to_s] =
    #  #    Algorithm::PointBased::Probabilistic::Combiner.new(@measurement_information[reader_power], tags_input[reader_power], false).
    #  #    set_settings(PointStepper.new(5), true).output
    #  #@algorithms['patent_comb_' + reader_power.to_s + 'no_weighting'] =
    #  #    Algorithm::PointBased::Probabilistic::Combiner.new(@measurement_information[reader_power], tags_input[reader_power], false).
    #  #    set_settings(PointStepper.new(5), false).output
    #
    #
    #
    #
    #  #%w(new).each do |regression_type|
    #  #  #@algorithms['tri_ls_rss_'+reader_power.to_s+'_'+type] =
    #  #  #    Algorithm::Trilateration.new(@measurement_information[reader_power][height]).
    #  #  #    set_settings(Optimization::LeastSquares, :rss, step, type).output
    #  #  @algorithms['tri_ls_rss_'+reader_power.to_s+'_'+regression_type] =
    #  #      Algorithm::Trilateration.new(@measurement_information[reader_power][height]).
    #  #      set_settings(Optimization::LeastSquares, :rss, step, regression_type).output
    #  #end
    #end













    #averager1 =
    #    Algorithm::PointBased::Meta::Averager.new(@algorithms, all_heights).
    #    set_settings(:all).output
    #averager2 =
    #    Algorithm::PointBased::Meta::Averager.new(@algorithms, all_heights).
    #    set_settings(:equal).output
    ##
    ##
    ##weights = []
    ##2.times{weights.push({:other => 0.4, '1' => 0.8, '2' => 0.8})}
    ##9.times{weights.push({:other => 0.2, '1' => 0.2, '2' => 0.2})}
    ##3.times{weights.push({:other => 0.3, '1' => 0.8, '2' => 0.8})}
    ##averager3 = Algorithm::PointBased::Meta::Averager.new(@algorithms, all_heights).
    ##    set_settings(:equal, weights).output
    #
    #weights = []
    #2.times{weights.push({:other => 0.4, '1' => 0.9, '2' => 0.3})}
    #9.times{weights.push({:other => 0.2, '1' => 0.0, '2' => 0.3})}
    #3.times{weights.push({:other => 0.3, '1' => 0.3, '2' => 0.3})}
    #averager4 = Algorithm::PointBased::Meta::Averager.new(@algorithms, all_heights).
    #    set_settings(:equal, weights).output
    #
    ##weights = []
    ##2.times{weights.push({:other => 0.4, '1' => 0.9, '2' => 0.3})}
    ##9.times{weights.push({:other => 0.2, '1' => 0.0, '2' => 0.0})}
    ##3.times{weights.push({:other => 0.3, '1' => 0.3, '2' => 0.3})}
    ##averager5 = Algorithm::PointBased::Meta::Averager.new(@algorithms, all_heights).
    ##    set_settings(:equal, weights).output
    ##
    ##weights = []
    ##2.times{weights.push({:other => 0.2, '1' => 0.4, '2' => 0.3, '3' => 0.2})}
    ##9.times{weights.push({:other => 0.4, '1' => 0.2, '2' => 0.1, '3' => 0.4})}
    ##3.times{weights.push({:other => 0.2, '1' => 0.9, '2' => 0.9, '3' => 1.6})}
    ##averager6 = Algorithm::PointBased::Meta::Averager.new(@algorithms, all_heights).
    ##    set_settings(:equal, weights).output
    #
    #
    #
    #tris = Hash[ @algorithms.map{|k,v|[k,v]}[0..1] ]
    #knns = Hash[ @algorithms.map{|k,v|[k,v]}[2..10] ]
    #knns_rss = Hash[ @algorithms.map{|k,v|[k,v]}[2..6] ]
    #knns_rr = Hash[ @algorithms.map{|k,v|[k,v]}[7..10] ]
    #zonals = Hash[ @algorithms.map{|k,v|[k,v]}[11..13] ]
    #
    #@algorithms['tris_combo'] = Algorithm::PointBased::Meta::Averager.new(tris, all_heights).
    #    set_settings(:equal).output
    #@algorithms['knns_combo'] = Algorithm::PointBased::Meta::Averager.new(knns, all_heights).
    #    set_settings(:equal).output
    #@algorithms['knns_combo_rss'] = Algorithm::PointBased::Meta::Averager.new(knns_rss, all_heights).
    #    set_settings(:equal).output
    #@algorithms['knns_combo_rr'] = Algorithm::PointBased::Meta::Averager.new(knns_rr, all_heights).
    #    set_settings(:equal).output
    #@algorithms['zonals_combo'] = Algorithm::PointBased::Meta::Averager.new(zonals, all_heights).
    #    set_settings(:equal).output
    #
    #@algorithms['combo_all_points'] = averager1
    #@algorithms['combo_equal_points'] = averager2
    ##@algorithms['combo_equal_points_weight3'] = averager3
    #@algorithms['combo_equal_points_weight4'] = averager4
    ##@algorithms['combo_equal_points_weight5'] = averager5
    ##@algorithms['combo_equal_points_weight6'] = averager6

    calc_tags_best_matches_for

    @algorithms
  end






















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






  def trilateration_map
    reader_power = 20
    tags_input = get_tags_input(reader_power)

    Algorithm::PointBased::Empirical2.new(@measurement_information[reader_power], tags_input, :one).
        set_settings(:rss, Optimization::LeastSquares, :circle, 0.0, 1.5).
        get_decision_function
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
    (0..3).each do |train_height|
      (0..3).each do |test_height|

        algorithms = @algorithms.select do |n, a|
          a.map[train_height].present? and a.map[train_height][test_height].present?
        end

        unless algorithms.empty?
          TagInput.tag_ids.each do |tag_id|
            min_error = algorithms.
                values.
                reject{|algorithm| algorithm.map[train_height][test_height][tag_id].nil?}.
                map{|algorithm| algorithm.map[train_height][test_height][tag_id][:error]}.
                reject{|error| error.nil? }.
                min

            algorithms_with_min_error = algorithms.reject do |name, algorithm|
              algorithm.map[train_height][test_height][tag_id].nil?
            end.select do |name, algorithm|
              algorithm.map[train_height][test_height][tag_id][:error] == min_error
            end

            algorithms_with_min_error.each do |name, algorithm|
              antennae_count_by_which_tag_read =
                  algorithm.map[train_height][test_height][tag_id][:answers_count]

              if antennae_count_by_which_tag_read > 0
                #puts name.to_s + ' ' + train_height.to_s + ' ' + test_height.to_s + ' ' + antennae_count_by_which_tag_read.to_s
                #puts algorithm.map[train_height][test_height].to_yaml
                algorithm.best_suited[train_height][test_height][:all] += 1.0
                algorithm.best_suited[train_height][test_height][antennae_count_by_which_tag_read] += 1.0
              end
            end
          end
        end

      end
    end
  end



end
