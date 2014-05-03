class Regression::DistancesMi < ActiveRecord::Base
  self.table_name = 'regression_distances_mi'
  self.inheritance_column = :inheritance_type

  attr_accessible :mi_type, :type, :height, :reader_power, :antenna_number, :const,
                  :mi_coeff, :angle_coeff, :mi_coeff_t, :angle_coeff_t
end
