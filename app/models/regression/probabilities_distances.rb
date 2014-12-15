class Regression::ProbabilitiesDistances < ActiveRecord::Base
	self.table_name = 'regression_probabilities_distances'
  attr_accessible :reader_power, :ellipse_ratio, :coeffs, :previous_rp_answered
end

