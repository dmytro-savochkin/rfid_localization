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
		@mi_type = :rr
    @mi_data = Parser.parse_tag_lines_data
		render 'main/mi_graphs'
  end
	def rss_graphs
		@mi_type = :rss
		@mi_data = Parser.parse_tag_lines_data
		render 'main/mi_graphs'
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
		@mi_type = :rss
    regression = Regression::ViewerDistancesMi.new(@mi_type)
    @graphs, @graph_limits, @coefficients_data, @correlation, @real_data = regression.get_data
	end

	def regression_rr_graphs
		@mi_type = :rr
		regression = Regression::ViewerDistancesMi.new(@mi_type)
		@graphs, @graph_limits, @coefficients_data, @correlation, @real_data = regression.get_data
		render 'main/regression_rss_graphs'
	end

	def rss_coverage
		@rss_map = MI::RssCoverage.generate_coverage


		#@rinruby = RinRuby.new(echo = false)
		#
		#
		#sigma = 50.0
		#estimated_sigmas = []
		#estimated_intervals = {'i1' => [], 'i2' => [], 'i3' => []}
		#l = 100
		#percent = 0.975
		#z = 1.96
		#
		#l.times do |i|
		#	values = []
		#	n = 500
		#	n.times do
		#		value = sigma * Math.sqrt(-2.0 * Math.log(rand()))
		#		values << value
		#	end
		#	estimated_sigma = Math.sqrt( values.map{|v| v**2}.sum / (2.0 * values.length) )
		#	estimated_sigmas << estimated_sigma
		#
		#	@rinruby.eval "quantile1 <- toString(qchisq(#{(1-percent)/2}, df=#{(2*values.length).to_s}))"
		#	@rinruby.eval "quantile2 <- toString(qchisq(#{1-(1-percent)/2}, df=#{(2*values.length).to_s}))"
		#	quantile1 = @rinruby.pull("quantile1").to_f
		#	quantile2 = @rinruby.pull("quantile2").to_f
		#
		#	range = [
		#			values.map{|e|e**2}.mean * values.length / quantile2,
		#			values.map{|e|e**2}.mean * values.length / quantile1
		#	]
		#	estimated_intervals['i1'] << range
		#
		#	d = z * Math.sqrt( (values.map{|v| v**2}.sum ** 2) / (4.0*values.length**3) )
		#	range = [estimated_sigma**2 - d, estimated_sigma**2 + d]
		#	estimated_intervals['i2'] << range
		#
		#	estimated_intervals['i3'] << z * Math.sqrt(
		#			( 2.0 * (4.0 - Math::PI) * values.mean*Math.sqrt(2.0/Math::PI) ** 2 ) / (2.0 * Math::PI * values.length)
		#	)
		#
		#end
		#
		#sorted = estimated_sigmas.sort
		#median = sorted[(l/2).round]
		#right = sorted[(l*percent).round]
		#left = sorted[(l*(1.0-percent)).round]
		#puts sorted.to_s
		#puts median.to_s
		#puts [left, right].to_s
		#
		#
		#puts ''
		#puts ''
		#
		#estimated_sigmas.each_with_index do |s, i|
		#	puts s.to_s
		#	puts (s ** 2).to_s
		#	puts (s * Math.sqrt(Math::PI/2.0)).to_s
		#	puts estimated_intervals['i1'][i].map{|e|Math.sqrt(e)}.to_s
		#	puts estimated_intervals['i1'][i].map{|e|Math.sqrt(e) * Math.sqrt(Math::PI/2.0)}.to_s
		#	puts estimated_intervals['i2'][i].to_s
		#	puts estimated_intervals['i2'][i].map{|e|Math.sqrt(e)}.to_s
		#	puts estimated_intervals['i2'][i].map{|e|Math.sqrt(e) * Math.sqrt(Math::PI/2.0)}.to_s
		#	puts estimated_intervals['i3'][i]
		#	puts ''
		#end
		#
		#25.00184528302129
		#[24.24587994495471, 25.782174078570016]







	end

end