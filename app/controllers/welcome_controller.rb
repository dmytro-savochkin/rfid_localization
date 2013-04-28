class WelcomeController < ApplicationController
  def index
    @algorithms = {}

    input = {
      :work_zone => WorkZone.new,
      :tags => Parser.parse(41, 20).values.first.values.first.values.first
    }


    #@algorithms[:tri] = Algorithm::Trilateration.new(input).set_settings(5).output

    @algorithms[:wknn_rss] = Algorithm::Knn.new(input).set_settings(:rss, 8, true).output
    @algorithms[:wknn_rr] = Algorithm::Knn.new(input).set_settings(:rr, 10, true).output

    sizes = [120, 75, :average]
    @algorithms[:zonal] = Algorithm::Zonal.new(input).set_settings(*sizes).output
    #@algorithms[:zonalr] = Algorithm::Zonal.new(input).set_settings(*sizes, :rectangles).output


    @algorithms[:combinational] = Algorithm::Combinational.new(input).set_settings(
        [
            @algorithms[:zonal].map,
            @algorithms[:wknn_rss].map,
            @algorithms[:wknn_rr].map
        ]
    ).output

    #@k_graph_data = Algorithm::Knn.make_k_graph(input, :rss, (1..17))
  end


  private

end