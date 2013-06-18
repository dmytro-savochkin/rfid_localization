class MainController < ApplicationController
  def algorithms
    #
    # TODO:
    #
    # - make a smart combinational algorithm (with "smart" estimating)
    # - neural networks, SVMs
    # - make adaptive combinational algorithm which depends on the count of antennae
    # which were used for receiving tags answers
    # - make greyscale version for flot
    # - caching
    # - make a possibility for displaying graph with circles (RSS to radii, etc.)
    # - find out the way to clean MI
    # - calibration for antennae (which antennae can be trusted more for results)
    # - refactoring

    #to think about rightfulness of this calculation of AlgorithmRunner#calc_best_matches_distribution


    algorithm_runner = AlgorithmRunner.new
    algorithm_runner.run_algorithms
    @tags_reads_by_antennae_count = algorithm_runner.calc_tags_reads_by_antennae_count
    algorithm_runner.calc_best_matches_distribution

    @algorithms = algorithm_runner.algorithms
  end



  def rr_graphs
    @rr_data = Parser.parse_tag_lines_data
  end

end