require 'mi/base'
require 'mi/a'
require 'algorithm/point_based/zonal/zones_creator'

class MainController < ApplicationController
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






















  def rss_rr_correlation
    mi = MI::Base.get_all_measurement_data
    @correlation = MI::Base.calc_rss_rr_correlation(mi)
  end



	def deviations
		deviations_calculator = Regression::Deviations.new
		@deviations = {}
		#@deviations[:position_random] = deviations_calculator.calculate_for_position_random
		#@deviations[:time_random] = deviations_calculator.calculate_for_time_random
		#@deviations[:antennas] = deviations_calculator.calculate_for_antennas
		@deviations[:reader_powers] = deviations_calculator.calculate_for_reader_powers

		#unnormalized_weights = [
		#		@deviations[:antennas][2.0][:stddev] * 0.75, # на глаз
		#		@deviations[:antennas][2.0][:stddev], @deviations[:reader_powers][2.0][:stddev],
		#		@deviations[:position_random][2.0][:stddev], @deviations[:time_random][2.0][:stddev]
		#]
		#@weights = unnormalized_weights.map{|w| w / unnormalized_weights.sum}
		@weights = []
	end

	def rss_time
		@graph_data = Parser.parse_time_tag_responses
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
    @graphs, @graph_limits, @coefficients_data, @correlation, @real_data = regression.get_data
  end

end