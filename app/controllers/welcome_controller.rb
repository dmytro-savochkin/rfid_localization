class WelcomeController < ApplicationController
  def index
    @algorithms = {}

    input = {
      :work_zone => WorkZone.new,
      :tags => Parser.parse.values.first.values.first.values.first
    }


    #@algorithms[:tril] = Trilateration.new(input).set_settings(50).output

    @algorithms[:wknn_rss] = Knn.new(input).set_settings(:rss, 8, true).output
    @algorithms[:wknn_rr] = Knn.new(input).set_settings(:rr, 16, true).output

    @algorithms[:combinational] = CombinationalAlgorithm.new(input).set_settings(
        [
            @algorithms[:wknn_rss].map,
            @algorithms[:wknn_rr].map
        ],
        [0.5, 0.5]
    ).output

    @k_graph_data = Knn.make_k_graph(input, :rss, (10..15))
  end


  private

end