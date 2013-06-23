class MainController < ApplicationController
  # these things are for caching
  require_dependency 'work_zone'
  require_dependency 'parser'
  require_dependency 'antenna'
  require_dependency 'tag_input'
  require_dependency 'point'


  def algorithms

    #
    # TODO:
    #
    # 1. calibration for antennae (which antennae can be trusted more for results)
    # - testing (at least unit testing)
    # 2. estimate algorithms complexity
    # 3. find out the way to clean MI
    # 4. neural networks, SVMs
    # 5. generate MI

    # Оценить вручную помогут ли коэффициенты

    # достоверность антенны (через коэффициенты ИИ и значения ИИ)

    # create two ways of displaying pdfs (aproximating histograms to pdfs and box-whiskers diagrams)


    # - make adaptive combinational algorithm which depends on the count of antennae
    # which were used for receiving tags answers
    # - make a possibility for displaying graph with circles (RSS to radii, etc.)


    algorithm_runner = AlgorithmRunner.new

    @algorithms = algorithm_runner.run_algorithms
    @tags_reads_by_antennae_count = algorithm_runner.calc_tags_reads_by_antennae_count

    @mi = algorithm_runner.measurement_information

    @ac = algorithm_runner.calc_antennae_coefficients
  end



  def rss_rr_correlation
    mi = MeasurementInformation::Base.parse
    @correlation = MeasurementInformation::Base.calc_rss_rr_correlation(mi)
  end


  def rr_graphs
    @rr_data = Parser.parse_tag_lines_data
  end

end