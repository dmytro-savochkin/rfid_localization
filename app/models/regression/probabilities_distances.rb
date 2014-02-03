class Regression::ProbabilitiesDistances < ActiveRecord::Base
  set_table_name 'regression_probabilities_distances'
  attr_accessible :reader_power, :ellipse_ratio, :coeffs
end

