class MainController < ApplicationController
  # for caching
  require_dependency 'work_zone'
  require_dependency 'parser'
  require_dependency 'antenna'
  require_dependency 'tag_input'
  require_dependency 'point'


  def main

    #
    # TODO:
    #
    # 0. svm (divide the field into 16 or more zones)
    # 1. calibration for antennae (which antennae can be trusted more for results)
    # - testing (at least unit testing)
    # 2. estimate algorithms complexity
    # 3. find out the way to clean MI
    # 4. neural networks
    # 5. generate MI

    # Оценить вручную помогут ли коэффициенты

    # достоверность антенны (через коэффициенты ИИ и значения ИИ)

    # - make adaptive combinational algorithm which depends on the count of antennae
    # which were used for receiving tags answers

    # написать скрипт для аппроксимации зависимости d(RSS) и d(RR) по excel файлам.
    #После этого еще раз JS (попробовать делать JS в самом начале и учитывать СКО каждой антенны по виду MI)

    # попробовать искать не maxL а среднее от L (EV)
    # возможно плохой вариант (улучшение если и будет то мало, а работать будет дольше (для 3L)

    # смоделить из блокнота

    # сделать два селекта для сравнения алгоритмов

    algorithm_runner = AlgorithmRunner.new

    @mi = algorithm_runner.measurement_information


    @algorithms = algorithm_runner.run_algorithms
    @tags_reads_by_antennae_count = algorithm_runner.calc_tags_reads_by_antennae_count


    #@trilateration_map_data =
    #    Algorithm::Trilateration.new(@mi[25][MeasurementInformation::Base::HEIGHTS.first]).
    #    set_settings(Optimization::JamesStein, :rss, 10).get_decision_function

    #@ac = algorithm_runner.calc_antennae_coefficients
  end



  def rss_rr_correlation
    mi = MeasurementInformation::Base.parse
    @correlation = MeasurementInformation::Base.calc_rss_rr_correlation(mi)
  end


  def rr_graphs
    @rr_data = Parser.parse_tag_lines_data
  end

end