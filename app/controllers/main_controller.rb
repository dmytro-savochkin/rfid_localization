class MainController < ApplicationController
  # for caching
  require_dependency 'work_zone'
  require_dependency 'parser'
  require_dependency 'antenna'
  require_dependency 'tag_input'
  require_dependency 'point'
  require_dependency 'regression'
  require_dependency 'regression/regression_model'


  def main

    #
    # TODO:
    #
    # 1. calibration for antennae (which antennae can be trusted more for results)
    # достоверность антенны (через коэффициенты ИИ и значения ИИ)
    #! 2. estimate algorithms complexity
    # 3. find out the way to clean MI
    # 5. generate MI
    # ! Adaboost и comboost !!    после этого все в екселе заново пересчитать


    # - make adaptive combinational algorithm which depends on the count of antennae
    # which were used for receiving tags answers

    # попробовать искать не maxL а среднее от L (EV)
    # возможно плохой вариант (улучшение если и будет то мало, а работать будет дольше (для 3L))



    algorithm_runner = AlgorithmRunner.new

    @mi = algorithm_runner.measurement_information


    @algorithms = algorithm_runner.run_algorithms
    @tags_reads_by_antennae_count = algorithm_runner.calc_tags_reads_by_antennae_count


    #@trilateration_map_data =
    #    Algorithm::Trilateration.new( @mi[20][MeasurementInformation::Base::HEIGHTS[0]] ).
    #    set_settings(Optimization::CosineMaximumProbability, :rss, 20).get_decision_function

    #@ac = algorithm_runner.calc_antennae_coefficients
  end



  def rss_rr_correlation
    mi = MeasurementInformation::Base.parse
    @correlation = MeasurementInformation::Base.calc_rss_rr_correlation(mi)
  end


  def rr_graphs
    @rr_data = Parser.parse_tag_lines_data
  end

  def regression
    regression = Regression::ModelCreator.new
    @regression_model = regression.create_models
  end

end