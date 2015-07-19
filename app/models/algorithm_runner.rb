class AlgorithmRunner
  attr_reader :algorithms, :mi


  def initialize
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

		generator = MiGenerator.new(:theoretical)
    all_heights = :all
    manager = TagSetsManager.new(
        all_heights,
        :real,
				false,
        {:train => 100, :setup => 50, :test => 400},
				30,
				generator
    )




    #@algorithms['e6'] =
    #    Algorithm::PointBased::Empirical.new(@measurement_information[20], get_tags_input(20), all_heights).
    #    set_settings(:rss, Optimization::LeastSquares, :six).output



    (20..20).each do |reader_power|
      puts 'POWER:' + reader_power.to_s

      [:rss].each do |mi_type|
        #[1.0, 1.01, 1.02, 1.03, 1.04, 1.05, 1.06, 1.07, 1.08, 1.09, 1.5].each do |ellipse_ratio|
        [1.5].each do |ellipse_ratio|
          #[0.0, 0.1, 0.2, 0.3, 0.4, 0.5].each do |rr_limit|
          #[0.0, 0.1, 0.3].each do |rr_limit|
          [0.0].each do |rr_limit|
            puts 'e'+ellipse_ratio.to_s + ' ' + rr_limit.to_s
            [:ellipse].each do |model_type|
              unless model_type == :circle and ellipse_ratio == 2.0
                #[:local_maximum, :global_maximum].each do |normalization|
                [:local_maximum].each do |normalization|
                  name = 'lin_tri_' + normalization.to_s + '_' + rr_limit.to_s.gsub(/\./, '') +
                      '_' + mi_type.to_s + '_' + reader_power.to_s + '_' + model_type.to_s +
                      'e' + ellipse_ratio.to_s.gsub(/\./, '')
                  @algorithms[name] =
                      Algorithm::PointBased::LinearTrilateration.new(reader_power, manager.id, manager.tags_input[reader_power]).
                      set_settings(mi_type, Optimization::LeastSquares, model_type, rr_limit, ellipse_ratio, normalization).output
                end
              end
            end
          end
        end

        puts 'TRI NOW'

        #[1.5].each do |ellipse_ratio|
        #  #[0.0, 0.1, 0.2, 0.3, 0.4, 0.5].each do |rr_limit|
        #  #[0.0, 0.1, 0.3].each do |rr_limit|
        #  [0.0].each do |rr_limit|
        #    [
        #        'powers=1__ellipse=' + ellipse_ratio.to_s,
        #        'powers=1__ellipse=' + ellipse_ratio.to_s + '_watt',
        #        #'powers=1,2__ellipse=' + ellipse_ratio.to_s,
        #        #'powers=1,2,3__ellipse=' + ellipse_ratio.to_s,
        #        'powers=1,2,3__ellipse=' + ellipse_ratio.to_s,
        #        'powers=1,2,3__ellipse=' + ellipse_ratio.to_s + '_watt',
        #        'new_elliptical',
        #        'new_elliptical_watt'
        #    ].each do |model_type|
        #      puts 't'+rr_limit.to_s + ' ' + model_type.to_s
        #      [:average].each do |antenna_type|
        #        name = rr_limit.to_s.gsub(/\./, '') + '_' + antenna_type.to_s + '_' + '_' +
        #            mi_type.to_s + '_' + reader_power.to_s + '_' +
        #            model_type.to_s.gsub(/[\.,=]/, '') + 'e' + ellipse_ratio.to_s.gsub(/\./, '')
        #        @algorithms['tri_w_' + name] =
        #            Algorithm::PointBased::Trilateration.new(reader_power, manager.id, manager.tags_input[reader_power]).
        #            set_settings(mi_type, Optimization::WeightedLeastSquares, antenna_type, model_type, rr_limit, ellipse_ratio).output
        #        @algorithms['tri_l_' + name] =
        #            Algorithm::PointBased::Trilateration.new(reader_power, manager.id, manager.tags_input[reader_power]).
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
    puts 'running'

    combinations = [
        #[:svm],
        #[:neural],
        #[:svm, :neural],
        #[:svm, :naive_bayes],
        [:svm, :neural, :naive_bayes],
        #[:naive_bayes, :neural],
        #[:naive_bayes, :hyperpipes],
        #[:neural, :hyperpipes],
        #[:neural, :naive_bayes, :hyperpipes],
        #[:neural, :naive_bayes, :svm],
        #[:neural, :naive_bayes, :hyperpipes, :svm],
        #[:ib1, :neural],
        #[:neural, :naive_bayes],
        #[:ib1, :neural, :svm],
        #[:ib1, :neural, :naive_bayes],
        #[:ib1, :neural, :svm, :naive_bayes],
        #[:ib1, :neural, :svm, :naive_bayes, :hyperpipes, :random_forest, :adaboost],
        #[:ib1, :neural, :svm, :naive_bayes, :hyperpipes],
        #[:ib1, :neural, :svm, :naive_bayes, :hyperpipes, :random_forest]
    ]




		frequency = 'multi'
		#mi_model_type = :theoretical
		mi_model_type = :empirical
		generator = MiGenerator.new(mi_model_type)
		all_heights = :all24
		manager = TagSetsManager.new(
				all_heights,
				:real,
				false,
				{:train => 144, :setup => 300, :test => 500},
				25,
				generator
		#{:train => 50, :setup => 50, :test => 50}
		#{:train => 5, :setup => 5, :test => 10}
		)
		tags_input = manager.tags_input[frequency]


		#classifiers = {}
		#all_classifiers = {}
		##classifiers_types = [:svm]
		#classifiers_types = [:svm, :neural, :naive_bayes]
		#(20..20).each do |reader_power|
		#	puts reader_power.to_s
		#	[:rss, :rr].each do |mi_type|
		#		classifiers_types.each do |classifier_type|
		#			puts classifier_type.to_s
		#			klass = ('Algorithm::Classifier::' + classifier_type.to_s.camelize).constantize
		#			current_classifier = klass.
		#					new(reader_power, manager.id, tags_input[reader_power], model_must_be_retrained).
		#					set_settings(mi_model_type, mi_type).output()
		#			if classifier_type != :ib1
		#				classifiers[classifier_type.to_s + reader_power.to_s + mi_type.to_s] = current_classifier
		#			end
		#			all_classifiers[classifier_type.to_s + reader_power.to_s + mi_type.to_s] = current_classifier
		#		end
		#	end
		#end
		## nearest mean is probably broken by call to TagInput
		#classifier = Algorithm::Classifier::Meta::Probabilistic::Sum.new(
		#		one_type_classifiers_hash( classifiers ), manager.id, tags_input[20]
		#).set_settings(Optimization::LeastSquares.new, {}).output



		model_must_be_retrained = false


    classifiers_types = [:svm, :neural, :naive_bayes]
    #classifiers_types = [:svm]
    classifiers_container = {}

    #weights_table = {
    #    :algorithm => {:neural => 0.7, :naive_bayes => 0.6, :hyperpipes => 0.5},
    #    :mi => {:rss => 0.7, :rr => 0.6}
    #}

    weights = {}
    (20..25).each do |reader_power|
      puts ''
      puts reader_power

      current_power_classifiers_container = {}

      [:rss, :rr].each do |type|
        puts ''
        puts type.to_s
        classifiers_types.each do |classifier_class|
          puts classifier_class.to_s
          klass = ('Algorithm::Classifier::' + classifier_class.to_s.camelize).constantize
          classifier_string = classifier_class.to_s
          classifier_name = classifier_string + '_' + type.to_s + '_' + reader_power.to_s

          algorithm = klass.new(reader_power, manager.id, tags_input[reader_power], model_must_be_retrained).
              set_settings(mi_model_type, type).output
          @algorithms[classifier_name] = algorithm
          #weights[classifier_name] = weights_table[:algorithm][classifier_class] * weights_table[:mi][type]
          classifiers_container[classifier_class] ||= {}
          current_power_classifiers_container[classifier_class] ||= {}
          classifiers_container[classifier_class][classifier_name] = algorithm
          current_power_classifiers_container[classifier_class][classifier_name] = algorithm
        end
      end



      #current_power
      #combinations.each do |combination|
      #  puts ''
      #  puts combination.map(&:to_s).join('_') + ' ' + reader_power.to_s
      #  data = Hash[ *combination.map{|e| one_type_classifiers_hash(current_power_classifiers_container[e]).to_a }.flatten(2) ]
      #  {:voter => nil, :knn => true, :knn_voter => 0.5}.each do |type, parameter|
      #    name = combination.map(&:to_s).join('_') + '_' + reader_power.to_s + '_' + type.to_s
      #    klass = ('Algorithm::Classifier::Meta::Numerical::' + type.to_s.camelize).constantize
      #    @algorithms[name] =
      #        klass.new(data, manager.id, tags_input[20]).set_settings(parameter).output
      #  end
      #end

      # from start power to end power
			if reader_power == 25
				combinations.each do |combination|
					puts combination.map(&:to_s).join('_') + ' diapasone ' + reader_power.to_s
					name = combination.map(&:to_s).join('_') + '_from_20_to_' + reader_power.to_s
					data = Hash[ *combination.map{|e| one_type_classifiers_hash(classifiers_container[e]).to_a }.flatten(2) ]
					#@algorithms[name] =
					#    Algorithm::Classifier::Meta::Numerical::KnnVoter.new(data, manager.id, tags_input[20]).
					#    set_settings(0.5).output

					#[:sum, :product, :min, :max, :weighted_sum, :weighted_zonal_sum,
					#    :weighted_covariance_sum, :nearest_mean
					#].each do |type|
					#[:sum, :weighted_sum, :knn
					[:sum, :weighted_sum, :knn
					].each do |type|
						puts type.to_s
						klass = ('Algorithm::Classifier::Meta::Probabilistic::' + type.to_s.camelize).constantize
						@algorithms[name + '_' + type.to_s] =
								klass.new(data, manager.id, tags_input[20]).
										set_settings(Optimization::LeastSquares.new, weights).output
					end
				end
			end


      #puts 'uppering bound'
      #@algorithms['upper_bound_20_to_' + reader_power.to_s] =
      #    Algorithm::Classifier::Meta::Numerical::UpperBound.new(
      #        full_classifiers_hash(classifiers_container), manager.id, tags_input[20]
      #    ).set_settings([]).output
    end

    #base_algorithms = @algorithms.dup




    #[Optimization::AngularCosineSimilarity, Optimization::LeastSquares,
    #    Optimization::HellingerDistance, Optimization::L3Distance
    #].each_with_index do |optimization, i|
    #[Optimization::LeastSquares,
    #    Optimization::HellingerDistance, Optimization::L3Distance
    #].each_with_index do |optimization, i|
    #[Optimization::LeastSquares, Optimization::HellingerDistance].each_with_index do |optimization, i|
    #  (1..15).each do |k|
    #    puts k.to_s
    #    [1,2,3,5,10,:all].each do |filter_length|
    #      @algorithms['combo_knn' + i.to_s + '_' + k.to_s + '_' + filter_length.to_s] =
    #          Algorithm::Classifier::Meta::Probabilistic::Knn.new(
    #              one_type_classifiers_hash( base_algorithms ), manager.id, tags_input[20]
    #          ).set_settings(optimization.new, k, filter_length).output
    #    end
    #  end
    #end


    puts 'ending'
    [@algorithms, tags_input]
  end














  def run_algorithms_with_classifying
    puts 'running'
    @algorithms = {}

    frequency = 'multi'
    apply_means_unbiasing = false
    model_must_be_retrained = false

		mi_model_type = :theoretical
		#mi_model_type = :empirical
		generator = MiGenerator.new(mi_model_type)
    all_heights = :basicx
    manager = TagSetsManager.new(
        all_heights,
				:virtual,
        false,
        {:train => 144, :setup => 300, :test => 2000},
				25,
				generator
        #{:train => 50, :setup => 50, :test => 50}
        #{:train => 5, :setup => 5, :test => 10}
    )
    tags_input = manager.tags_input[frequency]


    classifiers = {}
		#all_classifiers = {}
		##classifiers_types = [:naive_bayes]
		#classifiers_types = [:svm, :neural, :naive_bayes]
		#(20..25).each do |reader_power|
		#	puts reader_power.to_s
     # [:rss, :rr].each do |mi_type|
     #   classifiers_types.each do |classifier_type|
     #     puts classifier_type.to_s
     #     klass = ('Algorithm::Classifier::' + classifier_type.to_s.camelize).constantize
     #     current_classifier = klass.
     #         new(reader_power, manager.id, tags_input[reader_power], model_must_be_retrained).
     #         set_settings(mi_model_type, mi_type).output()
     #     if classifier_type != :ib1
     #       classifiers[classifier_type.to_s + reader_power.to_s + mi_type.to_s] = current_classifier
     #     end
     #     all_classifiers[classifier_type.to_s + reader_power.to_s + mi_type.to_s] = current_classifier
     #   end
     # end
		#end
		#
		## nearest mean is probably broken by call to TagInput
		#classifier = Algorithm::Classifier::Meta::Probabilistic::Sum.new(
     #   one_type_classifiers_hash( classifiers ), manager.id, tags_input[20]
		#).set_settings(Optimization::LeastSquares.new, {}).output
		#classifier2 = Algorithm::Classifier::Meta::Probabilistic::Knn.new(
		#		one_type_classifiers_hash( classifiers ), manager.id, tags_input[20]
		#).set_settings(Optimization::LeastSquares.new, {}).output


    #classifier2 = Algorithm::Classifier::Meta::KnnVoter.new(
    #    one_type_classifiers_hash( all_classifiers ), manager.id, tags_input[20]
    #).set_settings(0.5).output
    #
    #classifier3 = Algorithm::Classifier::Meta::Knn.new(
    #    one_type_classifiers_hash( all_classifiers ), manager.id, tags_input[20]
    #).set_settings(false).output
    #
    #indi_classifier = Algorithm::Classifier::NaiveBayes.
    #    new(20, manager.id, tags_input[20], model_must_be_retrained).
    #    set_settings(mi_model_type, :rss).output
    #puts 'CLASS_SUCCESS'
    #puts 'classifier: ' + classifier.classification_success.to_yaml
    #classifiers.each do |name, algorithm|
    #  puts name.to_s + algorithm.classification_success.to_yaml
    #end
    #puts 'classifier2: ' + classifier2.classification_success.to_yaml
    #puts 'classifier3: ' + classifier3.classification_success.to_yaml
    #puts ''
    #puts classifier.probabilities.to_yaml


    knns = {}
    knns_rss = {}
    knns_rr = {}
    knns_rss_rr_sum = {}
    zonals = {}
    tris = {}
		tris_rss = {}
		tris_rr = {}
		zonals_tris = {}
    only_rss = {}


    #(22..22).each do |reader_power|
    (20..25).each do |reader_power|
			#if mi_model_type == :theoretical
			#	range = MI::Rss.theoretical_range(reader_power)
			#	rss_limit = range[:min].to_f
			#else
				rss_limits = Regression::MiBoundary.where(:type => :rss, :reader_power => reader_power).first
				rss_limit = rss_limits.min.to_f
			#end
			rss_limit -= 4.0

			[8].each do |k|
        puts reader_power.to_s
        knn =
            Algorithm::PointBased::Knn.new(reader_power, manager.id, 1, tags_input[reader_power],
                model_must_be_retrained, apply_means_unbiasing).
                set_settings(mi_model_type, :rss, Optimization::LeastSquares, k, true, rss_limit).output
        name = 'wknn_ls_' + k.to_s + '_' + reader_power.to_s + '_rss_' + rss_limit.to_i.to_s
        @algorithms[name] = knn
        knns[name] = knn
        only_rss[name] = knn
        knns_rss_rr_sum[name] = knn
        knns_rss[name] = knn
      end
    end


    #(24..24).each do |reader_power|
    (20..25).each do |reader_power|
      [0.0].each_with_index do |default, default_index|
        [8].each do |k|
          [Optimization::LeastSquares].each_with_index do |opt, i|
          puts reader_power.to_s
          knn =
              Algorithm::PointBased::Knn.new(reader_power, manager.id, 2, tags_input[reader_power],
                  model_must_be_retrained, apply_means_unbiasing).
                  set_settings(mi_model_type, :rr, opt, k, true, default).output
          name = 'wknn_ls_' + reader_power.to_s + '_rr_' + k.to_s + '_' + i.to_s + default_index.to_s
          @algorithms[name] = knn
          knns[name] = knn
          knns_rss_rr_sum[name] = knn if reader_power == :sum
          knns_rr[name] = knn
          end
        end
      end
    end

    #(20..20).each do |reader_power|
    (20..22).each do |reader_power|
      puts reader_power.to_s
      zonal = Algorithm::PointBased::Zonal.new(reader_power, manager.id, 3, tags_input[reader_power],
          model_must_be_retrained, apply_means_unbiasing).
          #set_settings(mi_model_type, :ellipses, :rss, -72.5).output
          #set_settings(mi_model_type, :ellipses, :rss, -70.0).output
          set_settings(mi_model_type, :ellipses, :rss, -70.0).output
      name = 'zonal_70_' + reader_power.to_s
      @algorithms[name] = zonal
      zonals[name] = zonal
      zonals_tris[name] = zonal
    end



    rr_limits = {}
    #rr_limits[20] = 0.1
    #rr_limits[21] = 0.2
    #rr_limits[22] = 0.45
    #[:rss].each do |mi_type|
    [:rss, :rr].each do |mi_type|
      #(20..20).each do |reader_power|
      (20..22).each do |reader_power|
				[true].each do |penalty_for_antennas_without_answers|
					#rr_limit = 0.0 if mi_type == :rr
					#rr_limit = rr_limits[reader_power] if mi_type == :rss
					#[:ellipse, :not_ellipse].each do |model|
					[:ellipse].each do |model|
						puts reader_power.to_s
						tri =
								Algorithm::PointBased::LinearTrilateration.new(reader_power, manager.id, 4,
										tags_input[reader_power], model_must_be_retrained, apply_means_unbiasing).
										set_settings(mi_model_type, mi_type, Optimization::LeastSquares, model, 0.0, 1.5,
										:local_maximum, penalty_for_antennas_without_answers).output
						name = 'l_tri_' + reader_power.to_s + '_' + model.to_s + '_' + mi_type.to_s + '_' + penalty_for_antennas_without_answers.to_s
						@algorithms[name] = tri
						tris[name] = tri
						tris_rss[name] = tri if mi_type == :rss
						tris_rr[name] = tri if mi_type == :rr
						zonals_tris[name] = tri
					end
				end
      end
    end


		#(20..24).each do |reader_power|
		#	[
		#			#{:name => 'powers=1,2,3__ellipse=1.5', :ellipse => 1.5, :s => 'e'},
		#			{:name => 'powers=1,2__ellipse=1.0', :ellipse => 1.0, :s => 'ee', :penalty => false},
		#	#{:name => 'powers=1,2,3__ellipse=1.0', :ellipse => 1.0, :s => 'nf', :penalty => false}
		#	].each do |caze|
		#		[Optimization::LeastSquares].each_with_index do |opt, i|
		#			[:rss, :rr].each do |mi_type|
		#				puts reader_power.to_s
		#				tri =
		#						Algorithm::PointBased::Trilateration.new(reader_power, manager.id, 4,
		#								tags_input[reader_power], model_must_be_retrained, apply_means_unbiasing).
		#								set_settings(mi_model_type, mi_type, opt, :average, caze[:name].to_s, 0.0, caze[:ellipse]).output
		#				name = 'tri_'+reader_power.to_s+'_' + caze[:s].to_s + '_' + mi_type.to_s + '_' + i.to_s
		#				@algorithms[name] = tri
		#				tris[name] = tri
		#
		#				if mi_type == :rss
		#					only_rss[name] = tri
		#					tris_rss[name] = tri
		#				else
		#					tris_rr[name] = tri
		#				end
		#			end
		#		end
		#	end
		#end





    #ideal_probabilities = {}
    ##ideal_probabilities2 = {}
    ##ideal_probabilities3 = {}
    #(0...tags_input[20].length).each do |height_index|
    #  ideal_probabilities[height_index] ||= {}
    #  #ideal_probabilities2[height_index] ||= {}
    #  #ideal_probabilities3[height_index] ||= {}
    #  tags_input[20][0][:test].each do |tag|
    #    tag = tag.last
    #    ideal_probabilities[height_index][tag.id.to_s] = {}
    #    #ideal_probabilities2[height_index][tag.id.to_s] = {}
    #    #ideal_probabilities3[height_index][tag.id.to_s] = {}
    #    (1..16).each do |zone_number|
    #      zone_coordinates = Zone.new(zone_number).coordinates
		#
    #      #puts height_index.to_s + ' ' + tag.id.to_s
    #      zone_point = classifier.map[height_index][tag.id.to_s][:estimate] rescue nil
    #      zone_by_combo_classifier = Zone.number_from_point(zone_point)
		#
    #      #if zone_by_combo_classifier == zone_number
    #      #  ideal_probabilities3[height_index][tag.id.to_s][zone_coordinates] = 1.0
    #      #else
    #      #  ideal_probabilities3[height_index][tag.id.to_s][zone_coordinates] = 0.5
    #      #end
		#
    #      if tag.position.in_zone?(zone_number)
    #        ideal_probabilities[height_index][tag.id.to_s][zone_coordinates] = 1.0
    #        #ideal_probabilities2[height_index][tag.id.to_s][zone_coordinates] = 1.0
    #      else
    #        ideal_probabilities[height_index][tag.id.to_s][zone_coordinates] = 0.01
    #        #ideal_probabilities2[height_index][tag.id.to_s][zone_coordinates] = 0.5
    #      end
    #    end
    #  end
    #end

    #puts ''
    #puts 'PROBABILITIES:::'
    #puts 'class' + classifier.probabilities.to_yaml
    #puts 'class2' + classifier2.probabilities.to_yaml
    #puts 'indi' + indi_classifier.probabilities.to_yaml
    #puts 'ideal1' + ideal_probabilities.to_yaml
    #puts 'ideal2' + ideal_probabilities2.to_yaml
    #puts 'ideal3' + ideal_probabilities3.to_yaml
    #puts ''







		all_algorithms = @algorithms.dup

		#[false].each do |classifying|
		##[false, true].each do |classifying|
		##	[all_algorithms, knns, knns_rss, knns_rr, zonals, tris, tris_rss, tris_rr].each_with_index do |group, i|
		#	#[knns, knns_rss, knns_rr].each_with_index do |group, i|
		#	#[all_algorithms, tris_rss, tris_rr].each_with_index do |group, i|
		#	[all_algorithms].each_with_index do |group, i|
		#
		#		[
		#				[false, false, false, false, false],
		#
		#				#[true,  false, false, false, false],
		#				#[false, true,  false, false, false],
		#				#[true,  true,  false, false, false],
		#				#[false, false, :stddev, false, false],
		#				#[false, false, :four_or_more, false, false],
		#				#[false, false, :mean, false, false],
		#				#[false, false, :bordered, false, false],
		#				#[true, true, :stddev, false, false],
		#				#[true, true, :mean, false, false],
		#				#[true, true, :bordered, false, false],
		#				#[true, false, :stddev, false, false],
		#				#[true, false, :bordered, false, false],
		#
		#
		#				#[false, false, false, :error, false],
		#				#[false, false, false, :error_x_y, false],
		#				#[false, false, true,  :error, false],
		#				#[false, false, true,  :error_x_y, false],
		#				#[false, false, false, :different, false],
		#				#[false, false, true,  :different, false],
		#				#
		#				#[true, false, true,  :error_x_y, false],
		#				#[true, true, true,  :error_x_y, false]
		#		].each do |variant|
		#			apply_centroid_weighting = variant[0]
		#			special_case_one_antenna = variant[1]
		#			apply_stddev_weighting = variant[2]
		#			correlation_weighting = variant[3]
		#			special_case_small_variances = false
		#			variance_decrease_coefficient = 1.0
		#
		#
		#			name = 'asw-'+apply_stddev_weighting.to_s+'-'+
		#					'corr-'+correlation_weighting.to_s+'-'+
		#					'1ant-'+special_case_one_antenna.to_s+'-'+
		#					'cent-'+apply_centroid_weighting.to_s
		#
		#
		#			if classifying
		#				[:always].each do |classifier_mode|
		#				#[:always, :not_always].each do |classifier_mode|
		#					name2 = name + classifier_mode.to_s
		#					puts '======================================================'
		#					puts name2.to_s + ' is going'
		#					@algorithms['combo_class_' + i.to_s + '_' + name2] =
		#							Algorithm::PointBased::Meta::ProbabilisticAverager.
		#									new(group, manager.id, 5, tags_input[20]).
		#									set_settings(
		#									apply_stddev_weighting,
		#									correlation_weighting,
		#									special_case_one_antenna,
		#									special_case_small_variances,
		#									apply_centroid_weighting,
		#									variance_decrease_coefficient,
		#									:each, classifier.probabilities, classifier_mode).output
		#					@algorithms['combo_class2_' + i.to_s + '_' + name2] =
		#							Algorithm::PointBased::Meta::ProbabilisticAverager.
		#									new(group, manager.id, 5, tags_input[20]).
		#									set_settings(
		#									apply_stddev_weighting,
		#									correlation_weighting,
		#									special_case_one_antenna,
		#									special_case_small_variances,
		#									apply_centroid_weighting,
		#									variance_decrease_coefficient,
		#									:each, classifier2.probabilities, classifier_mode).output
		#					#@algorithms['combo_ideal_' + i.to_s + '_' + name2] =
		#					#		Algorithm::PointBased::Meta::ProbabilisticAverager.
		#					#				new(group, manager.id, 5, tags_input[20]).
		#					#				set_settings(
		#					#				apply_stddev_weighting,
		#					#				correlation_weighting,
		#					#				special_case_one_antenna,
		#					#				special_case_small_variances,
		#					#				variance_decrease_coefficient,
		#					#				apply_centroid_weighting,
		#					#				:each, ideal_probabilities, classifier_mode).output
		#				end
		#			else
		#				puts name.to_s + ' is going'
		#				@algorithms['combo__' + i.to_s + name.to_s] = Algorithm::PointBased::Meta::Averager.
		#						new(group, manager.id, 5, tags_input[20]).set_settings(
		#						apply_stddev_weighting,
		#						correlation_weighting,
		#						special_case_one_antenna,
		#						special_case_small_variances,
		#						apply_centroid_weighting,
		#						variance_decrease_coefficient,
		#						:each,
		#						nil
		#				).output
		#			end
		#			puts 'done'
		#			puts '======================================================'
		#		end
		#	end
		#
		#end
		#
		#
		#
		#
		#
		#
		#
     ###@algorithms['combo__' + i.to_s + 'f'] = Algorithm::PointBased::Meta::Averager.
     ###    new(group, manager.id, tags_input[20]).set_settings(false, :each).output
     ###@algorithms['combo__' + i.to_s + 't'] = Algorithm::PointBased::Meta::Averager.
     ###    new(group, manager.id, tags_input[20]).set_settings(true, :each).output
		#	#
     ###[false].each do |apply_stddev_weighting|
     ##[false, :sum].each do |apply_stddev_weighting|
		#		#next if group != all_algorithms and apply_stddev_weighting == :antenna_count
     ###[false, :all, :antenna_count].each do |apply_stddev_weighting|
     ###[false].each do |apply_stddev_weighting|
     ##  other = [false, true] if apply_stddev_weighting
     ##  other = [false] if ! apply_stddev_weighting
     ##  [false, :error, :error_x_y].each do |correlation_weighting|
     ##  #[false, :brownian, :rv, :error].each do |correlation_weighting|
     ##  #[false].each do |correlation_weighting|
     ##  #  [false, true].each do |special_case_one_antenna|
     ##    [false].each do |special_case_one_antenna|
     ##      [false].each do |special_case_small_variances|
		#		#			next if special_case_small_variances and !apply_stddev_weighting
     ##        #[1.0].each do |variance_decrease_coefficient|
     ##        variance_decrease_coefficients = [1.0]
     ##        #if apply_stddev_weighting and model_must_be_retrained
     ##        #  variance_decrease_coefficients = [1.0, 0.9, 0.8, 0.5]
     ##        #end
     ##        variance_decrease_coefficients.each do |variance_decrease_coefficient|
     ##          cases_name =
		#		#						'asw-'+apply_stddev_weighting.to_s+'-'+
		#		#						'corr-'+correlation_weighting.to_s+'-'+
     ##              '1ant-'+special_case_one_antenna.to_s+'-'+
		#		#						'svar-'+special_case_small_variances.to_s+'-'
     ##              #variance_decrease_coefficient.to_s.gsub(/\./, '')
		#	#
     ##          puts cases_name.to_s + ' is running'
		#	#
     ##          #[false, true].each do |apply_centroid_weighting|
     ##          [false].each do |apply_centroid_weighting|
		#		#					next if group != all_algorithms and apply_centroid_weighting == true
     ##            if correlation_weighting
     ##              correlation_lengths = [nil]
     ##            else
     ##              correlation_lengths = [nil]
     ##            end
     ##            correlation_lengths.each do |correlation_length|
		#	#
		#	#
		#	#
		#	#
     ##              cases2_name = cases_name +
		#		#								'cent-'+apply_centroid_weighting.to_s+
		#		#								correlation_length.to_s
		#	#
     ##              @algorithms['combo__' + i.to_s + cases2_name.to_s] = Algorithm::PointBased::Meta::Averager.
     ##                  new(group, manager.id, 5, tags_input[20]).set_settings(
     ##                  apply_stddev_weighting,
     ##                  correlation_weighting,
     ##                  special_case_one_antenna,
     ##                  special_case_small_variances,
     ##                  apply_centroid_weighting,
     ##                  variance_decrease_coefficient,
     ##                  :each,
     ##                  correlation_length
     ##              ).output
		#	#
		#	#
     ##              #[:always, :not_always].each do |classifier_mode|
     ##              #  cases3_name = cases2_name + classifier_mode.to_s
     ##              #  @algorithms['combo_class_' + i.to_s + '_' + cases3_name] =
     ##              #      Algorithm::PointBased::Meta::ProbabilisticAverager.
     ##              #          new(group, manager.id, 5, tags_input[20]).
     ##              #          set_settings(
     ##              #          apply_stddev_weighting,
     ##              #          correlation_weighting,
     ##              #          special_case_one_antenna,
     ##              #          special_case_small_variances,
     ##              #          apply_centroid_weighting,
     ##              #          variance_decrease_coefficient,
     ##              #          :each, classifier.probabilities, classifier_mode).output
		#		#						#
     ##              #  @algorithms['combo_ideal_' + i.to_s + '_' + cases3_name] =
     ##              #      Algorithm::PointBased::Meta::ProbabilisticAverager.
     ##              #          new(group, manager.id, 5, tags_input[20]).
     ##              #          set_settings(
     ##              #          apply_stddev_weighting,
     ##              #          correlation_weighting,
     ##              #          special_case_one_antenna,
     ##              #          special_case_small_variances,
     ##              #          variance_decrease_coefficient,
     ##              #          apply_centroid_weighting,
     ##              #          :each, ideal_probabilities, classifier_mode).output
		#		#						#
     ##              #  #@algorithms['combo_ideal3_' + i.to_s + '_' + cases3_name] =
     ##              #  #    Algorithm::PointBased::Meta::ProbabilisticAverager.
     ##              #  #        new(group, manager.id, 6, tags_input[20]).
     ##              #  #        set_settings(
     ##              #  #        apply_stddev_weighting,
     ##              #  #        apply_correlation_weighting,
     ##              #  #        special_case_one_antenna,
     ##              #  #        special_case_small_variances,
     ##              #  #        variance_decrease_coefficient,
     ##              #  #        apply_centroid_weighting,
     ##              #  #        :each, ideal_probabilities3, classifier_mode).output
     ##              #end
     ##            end
     ##          end
     ##        end
		#	#
     ##      end
     ##    end
     ##  end
     ##end
		##end



		combos = @algorithms.dup.keep_if{|name, a| a.instance_variable_defined?('@algorithms')}
    #@algorithms = @algorithms.keep_if{|k,v| k.to_s.match(/^combo/)}



    classifiers_output = classifiers
    #classifiers_output[:combo] = classifier

    puts 'ending'

    [@algorithms, classifiers_output, manager]
  end






  def trilateration_map
    manager = TagSetsManager.new(:basicx, :real)
    Algorithm::PointBased::Trilateration.new(20, manager.id, 1,
        manager.tags_input['multi'][20], false, false).
        set_settings(:empirical, :rss, Optimization::LeastSquares, :average, 'powers=1,2,3__ellipse=1.0', 0.0, 1.0).
        get_decision_function
	end

	def linear_trilateration_map
		generator = MiGenerator.new(:empirical)
		all_heights = :basicx
		manager = TagSetsManager.new(
				all_heights,
				:real,
				false,
				{:train => 144, :setup => 300, :test => 2500},
				30,
				generator
		)
		tags_input = manager.tags_input['multi']
		Algorithm::PointBased::LinearTrilateration.new(20, manager.id, 4,
						tags_input[20], false, false).
						set_settings(:empirical, :rss, Optimization::LeastSquares, :ellipse, 0.0, 1.5,
						:local_maximum, true).get_decision_function
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



  def calc_antennae_coefficients(mi, algorithms)
    coefficients_finder = AntennaeCoefficientsFinder.new(mi, algorithms)
    {
        :by_mi => coefficients_finder.coefficients_by_mi
        #:by_algorithms => coefficients_finder.coefficients_by_algorithms
    }
  end











  private





  def one_type_classifiers_hash(classifiers_container)
    Hash[classifiers_container.map do |k,v|
      [k, {
          classification_success: v.classification_success,
          map: v.map,
          setup: v.setup,
          probabilities: v.probabilities
      }]
    end]
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
