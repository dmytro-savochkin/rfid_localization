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

  def rss_rr_correlation
    mi = MI::Base.get_all_measurement_data
    @correlation = MI::Base.calc_rss_rr_correlation(mi)
  end



	def deviations
		deviations_calculator = Regression::Deviations.new
		@deviations = {}
		@deviations[:reader_powers] = deviations_calculator.calculate_for_reader_powers
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
	end

end