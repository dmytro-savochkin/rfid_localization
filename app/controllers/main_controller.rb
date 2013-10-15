class MainController < ApplicationController
  # for caching
  require_dependency 'work_zone'
  require_dependency 'parser'
  require_dependency 'antenna'
  require_dependency 'tag_input'
  require_dependency 'point'
  require_dependency 'regression'
  require_dependency 'regression/regression_model'


  #
  # TODO:
  #


  #
  # СТАТЬЯ по трилатерации:
  #
  # 5 вариантов (различные высоты, мощности, ИИ):
  # 1) only circular
  # 2) elliptical with a/b
  # 3) RSS weighting
  # 4) heuristics with 1,2 answers tags
  # 5) отбрасывание RSS, если мал RR
  # 6) everything
  # Посмотреть эмпирику на RR.
  # проверить нужно ли в linear_trilateration делать opposite_angle



  #
  # ТЕМА коэффициентов антенн:
  #
  # вектора СКО ошибки по антеннам слабо коррелируют, нормальная корреляция есть при мощности
  # 22 дБм и выше. С ней и нужно будет дальше работать. Также разобрать случай моделирования
  # плохой антенны (с плохой точностью).
  # Также еще вариант задания к-тов антеннам по результатам работы алгоритма. А также случай
  # их задания путем выкидывания антенн при оценке (если и без нее хорошо работает, то к-т мал)










  # ПРОВЕРИТЬ РАБОТУ:
  # 1) сделать три разных варианта учета вероятностей в вероятностном усреднителе (из блокнота)
  # 2) сделать реальные классификаторы (вроде сделан только naive bayes, проверять сначала его)

  # какая-то фигня с угловыми метками (в самом углу) - неправильно усредняются
  # поэтому третий способ плох

  # !!!! - выводить в инфе  справа информацию о к-тах получающихся по вероятностям (или оценки)

  # - добавить RR генерацию
  # - нужен рефакторинг base, point_based и classifier





  # нужно ли при генерации использовать полученные для различных высот выражения?

  # делать коррекцию по результатам setup: сдвигать на МО, учитывать весовой к-т по stddev

  # в статье три пункта новизны: объединение методов и видов ИИ; классификация + лок.;
  # объединенные оценки по числу антенн ответивших

  # в работе можно объединять по выборочной дисперсии







  # find out the way to clean MI
  # в классификаторах возможно еще и 4 зоны, 9 зон
  # добавить простой метод Роккио (описан в материалах конференции its2012) через близость к центроиду

  # попробовать искать не maxL а среднее от L (EV)
  # возможно плохой вариант (улучшение если и будет то мало, а работать будет дольше (для 3L))

  # опробовать вариант трилатерации из статьи (находить пересечения парных эллипсов, при этом выполнять
  # взвешивание по значениям RSS)
  # "Accurate Passive RFID Localization System for Smart Homes"

  # вся классификация может быть переведена на вывод вероятности нахождения в зоне.
  # В этом случае это открывает много возможностей для уточнения зон (наиболее популярная, вторая после нее и т.д.)



  def classifier
    algorithm_runner = AlgorithmRunner.new
    @mi = algorithm_runner.mi
    @algorithms = algorithm_runner.run_classifiers_algorithms
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
    algorithms, tags_input = algorithm_runner.run_algorithms_with_classifying
    @algorithms = clean_algorithms_data(algorithms)

    #@tags_reads_by_antennae_count = algorithm_runner.calc_tags_reads_by_antennae_count
    #@ac = algorithm_runner.calc_antennae_coefficients(tags_input, @algorithms)
  end










  def rss_rr_correlation
    mi = MI::Base.parse
    @correlation = MI::Base.calc_rss_rr_correlation(mi)
  end





  def rr_graphs
    @rr_data = Parser.parse_tag_lines_data
  end

  def regression
    regression = Regression::ModelCreator.new
    @errors = regression.create_models
  end




  private

  def clean_algorithms_data(algorithms)
    algorithms.each do |algorithm_name, algorithm|
      hash = Hash.new
      [:map, :reader_power, :errors_parameters, :cdf, :pdf, :map, :errors, :best_suited,
          :tags_input, :heights_combinations, :setup].each do |var_name|
        hash[var_name] = algorithm.send(var_name)
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

end






