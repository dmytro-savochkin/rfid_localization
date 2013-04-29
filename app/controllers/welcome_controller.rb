class WelcomeController < ApplicationController
  def index
    @algorithms = {}


    #TODO: make a smart combinational algorithm (with "smart" estimating)
    #TODO: choose better ellipses' sizes for zonal method

    height = 41
    powers_to_sizes = {
      20 => [120, 75],
      21 => [120, 90],
      22 => [120, 90],
      23 => [120, 90],
      24 => [130, 110]
    }
    input = {}
    (20..24).each do |reader_power|
      input[reader_power] = {
          :work_zone => WorkZone.new,
          :tags => Parser.parse(height, reader_power).values.first.values.first.values.first
      }

      @algorithms['zonal'+reader_power.to_s] =
          Algorithm::Zonal.new(input[reader_power]).
          set_settings(*powers_to_sizes[reader_power], :adaptive, :ellipses).output
    end

    names_to_combinational = ['zonal20', 'zonal21', 'zonal22', 'zonal23', 'zonal24']
    @algorithms[:zonal_comb] = Algorithm::Combinational.new(input[20]).set_settings(
        names_to_combinational.map {|name| @algorithms[name].map}
    ).output




    #@algorithms[:tri] = Algorithm::Trilateration.new(input).set_settings(5).output

    @algorithms[:wknn_rss] = Algorithm::Knn.new(input[20]).set_settings(:rss, 8, true).output
    @algorithms[:wknn_rr] = Algorithm::Knn.new(input[20]).set_settings(:rr, 10, true).output


    #@algorithms[:zonal_rectangles] = Algorithm::Zonal.new(input[20]).set_settings(*sizes, :rectangles).output


    @algorithms[:wknn] = Algorithm::Combinational.new(input[20]).set_settings(
        [@algorithms[:wknn_rss].map, @algorithms[:wknn_rr].map]
    ).output

    @algorithms[:result] = Algorithm::Combinational.new(input[20]).set_settings(
        [@algorithms[:wknn].map, @algorithms[:zonal_comb].map]
    ).output

    @algorithms[:resultt] = Algorithm::Combinational.new(input[20]).set_settings(
        [@algorithms[:wknn_rss].map, @algorithms[:zonal_comb].map]
    ).output


    #@k_graph_data = Algorithm::Knn.make_k_graph(input, :rss, (1..17))
  end


  private

end