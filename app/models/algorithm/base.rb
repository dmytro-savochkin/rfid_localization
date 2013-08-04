class Algorithm::Base
  attr_reader :cdf, :histogram, :tags_test_output, :map, :errors_parameters,
              :estimates_parameters,  :show_in_chart, :tags_test_input, :compare_by_antennae,
              :reader_power, :work_zone, :errors
  attr_accessor :best_suited_for



  def initialize(input, compare_by_antennae = true, show_in_chart = {:main => true, :histogram => true},
      use_antennae_matrix = true)
    @work_zone = input[:work_zone]
    @tags_test_input = input[:tags_test_input]
    @reader_power = input[:reader_power]
    @compare_by_antennae = compare_by_antennae
    @show_in_chart = show_in_chart
    @use_antennae_matrix = use_antennae_matrix
  end


  def set_settings() end


end