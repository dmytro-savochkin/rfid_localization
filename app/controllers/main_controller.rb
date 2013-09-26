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
  # - calibration for antennae (which antennae can be trusted more for results)
  #   достоверность антенны (через коэффициенты ИИ и значения ИИ)
  #   это должно быть при тренировке алгоритма, например, по RSS в дальность и МНК

  # - все калибровки (чисто по алгоритму и по количеству антенн) привести в порядок + рефакторинг
  # - make adaptive combinational algorithm which depends on the count of antennae
  #   which were used for receiving tags answers
  # - сделать трилатерацию на адаптивный RSS (отбрасывать значения если мал RR)




  # 5 вариантов (различные высоты, мощности, ИИ):
  # 1) only circular
  # 2) elliptical with a/b
  # 3) RSS weighting
  # 4) heuristics with 1,2 answers tags
  # 5) everything

  # почему такие слабо выраженные эллипсы?

  # Посмотреть эмпирику на RR.




  # 1. в трилатерации рассмотреть еще по разному модель регрессии, пооценивать прямо в model_creator
  # влияние разных слагаемых. Подобрать таким образом нужную степень.





  # find out the way to clean MI
  # generate MI
  # в классификаторах возможно еще и 4 зоны, 9 зон

  # попробовать искать не maxL а среднее от L (EV)
  # возможно плохой вариант (улучшение если и будет то мало, а работать будет дольше (для 3L))

  # опробовать вариант трилатерации из статьи (находить пересечения парных эллипсов, при этом выполнять
  # взвешивание по значениям RSS)
  # "Accurate Passive RFID Localization System for Smart Homes"

  # вся классификация может быть переведена на вывод вероятности нахождения в зоне.
  # В этом случае это открывает много возможностей для уточнения зон (наиболее популярная, вторая после нее и т.д.)



  def classifier
    algorithm_runner = AlgorithmRunner.new
    @mi = algorithm_runner.measurement_information
    @algorithms = algorithm_runner.run_classifiers_algorithms
  end




  def point_based
    algorithm_runner = AlgorithmRunner.new
    @mi = algorithm_runner.measurement_information


    algorithms = algorithm_runner.run_point_based_algorithms
    algorithms.each do |algorithm_name, algorithm|
      hash = Hash.new
      [:map, :reader_power, :errors_parameters, :cdf, :pdf, :map, :errors, :best_suited, :tags_input].each do |var_name|
        hash[var_name] = algorithm.send(var_name)
      end
      algorithms[algorithm_name] = hash
    end
    @algorithms = algorithms



    #@tags_reads_by_antennae_count = algorithm_runner.calc_tags_reads_by_antennae_count
    #@ac = algorithm_runner.calc_antennae_coefficients




    #@trilateration_map_data = algorithm_runner.trilateration_map
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

end






