class MainController < ApplicationController
  # for caching
  require_dependency 'work_zone'
  require_dependency 'parser'
  require_dependency 'antenna'
  require_dependency 'tag_input'
  require_dependency 'point'
  require_dependency 'regression'
  require_dependency 'regression/distances_mi'
  require_dependency 'regression/probabilities_distances'


  #
  # TODO:
  #


  #
  # СТАТЬЯ по моделированию
  #
  # 2. Нужно будет добавить постоянную ошибку
	# - для области
	# - для области и антенны
	# - для области и мощности
	# - для области, мощности и частоты ?
	# - случайную ошибку.
  #
  # 1. Нужно при виртуальной генерации создавать данные не для каждого элемента в height_combinations,
  # а по каждому уникальному номеру высоты (то есть чтобы 0-1 и 2-1 для zonals давали одинаковый
  # результат)
  #
  # 0. нужно ли при генерации использовать полученные для различных высот выражения d(rss)?
  #
  # ! поискать нормальность для руби!
	#
  # рефакторинг!
	# генерировать отдельно для каждой комбинации высот!








  #
  # ТЕМА коэффициентов антенн:
  #
  # вектора СКО ошибки по антеннам слабо коррелируют, нормальная корреляция есть при мощности
  # 22 дБм и выше. С ней и нужно будет дальше работать. Также разобрать случай моделирования
  # плохой антенны (с плохой точностью).
  # Также еще вариант задания к-тов антеннам по результатам работы алгоритма. А также случай
  # их задания путем выкидывания антенн при оценке (если и без нее хорошо работает, то к-т мал)
  #








  # обучаем (1-й набор), калибруем (2-й набор), обучаем (2-й набор), тестируем (3-й набор)
  # посмотреть на сколько изменятся в этом случае stddev при втором обучении, найти
  # приблизительный к-т уменьшения stddev и затем его использовать в общем случае

  # а что будет если исключить сетап, но обучать по трехстам меткам? (становится лучше)
  # что будет если веса не по антеннам а вообще?    (становится хуже)
  # что будет если ввести взвешивание экспертное только по случаю 1-й антенны (проверить
  # с double_train)

  # апдейтить корреляцию каждый раз при получении новых оценок
  # Обратить внимание на 0D02 на первой высоте


  # - при аппроксимации значения вероятности нахождения в точке использовать не линейную
  # зависимость от четырех ближайших антенн, а нелинейную (закругленные уступы)








  # find out the way to clean MI
  # в классификаторах возможно еще и 4 зоны, 9 зон
  # добавить простой метод Роккио (описан в материалах конференции its2012) через близость к центроиду

  # попробовать искать не maxL а среднее от L (EV)
  # возможно плохой вариант (улучшение если и будет то мало, а работать будет дольше (для 3L))

  # опробовать вариант трилатерации из статьи (находить пересечения парных эллипсов, при этом выполнять
  # взвешивание по значениям RSS)
  # "Accurate Passive RFID Localization System for Smart Homes"



  def classifier
    algorithm_runner = AlgorithmRunner.new
    @mi = algorithm_runner.mi
    algorithms, @tags_input = algorithm_runner.run_classifiers_algorithms
    @algorithms = clean_algorithms_data(algorithms)
  end


  def point_based
    algorithm_runner = AlgorithmRunner.new
    @mi = algorithm_runner.mi

    algorithms = algorithm_runner.run_point_based_algorithms
    @algorithms = clean_algorithms_data(algorithms)

    #@tags_reads_by_antennae_count = algorithm_runner.calc_tags_reads_by_antennae_count
    #@ac = algorithm_runner.calc_antennae_coefficients

    #@trilateration_map_data = algorithm_runner.trilateration_map
  end


  def point_based_with_classifying
    algorithm_runner = AlgorithmRunner.new
    @mi = algorithm_runner.mi
    algorithms, classifiers, tags_input = algorithm_runner.run_algorithms_with_classifying
    @algorithms = clean_algorithms_data(algorithms)
    @classifiers = clean_classifier_data(classifiers)

    #@trilateration_map_data = algorithm_runner.trilateration_map
    #@tags_reads_by_antennae_count = algorithm_runner.calc_tags_reads_by_antennae_count
    #@ac = algorithm_runner.calc_antennae_coefficients(tags_input, @algorithms)
  end










  def rss_rr_correlation
    mi = MI::Base.get_all_measurement_data
    @correlation = MI::Base.calc_rss_rr_correlation(mi)
  end








  def rr_graphs
    @rr_data = Parser.parse_tag_lines_data
  end

  def regression
    regression = Regression::CreatorDistancesMi.new
    @models, @errors, @deviations, @deviations_normality = regression.create_models
  end

  def response_probabilities
    regression = Regression::CreatorProbabilitiesDistances.new
    @probabilities, @models, @correlation, @graphs = regression.calculate_response_probabilities
  end

  def regression_rss_graphs
    regression = Regression::ViewerDistancesMi.new
    @graphs, @graph_limits, @coefficients_data, @correlation = regression.get_data
  end









    private

  def clean_algorithms_data(algorithms)
    algorithms.each do |algorithm_name, algorithm|
      hash = Hash.new
      [:map, :reader_power, :errors_parameters, :cdf, :pdf, :map, :errors, :best_suited,
          :tags_input, :heights_combinations, :setup, :probabilities_with_zones_keys,
          :classification_parameters, :classification_success, :work_zone, :group
      ].each do |var_name|
        hash[var_name] = algorithm.send(var_name) if algorithm.respond_to?(var_name)
      end
      if algorithm.instance_variable_defined?("@algorithms")
        hash[:combiner] = true
      else
        hash[:combiner] = false
      end
      algorithms[algorithm_name] = hash
    end
    algorithms
  end

  def clean_classifier_data(classifiers)
    hash = Hash.new

    classifiers.each do |classifier_name, classifier|
      hash[classifier_name] ||= {}
      [:probabilities, :classification_success].each do |var_name|
        if classifier.respond_to?(var_name)
          hash[classifier_name][var_name] = classifier.send(var_name)
        end
      end
    end

    hash
  end

end






