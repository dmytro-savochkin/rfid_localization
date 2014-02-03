class Regression::MiBoundary < ActiveRecord::Base
  set_table_name 'regression_mi_boundaries'
  self.inheritance_column = :inheritance_type
  attr_accessible :type, :reader_power, :min, :max
end
