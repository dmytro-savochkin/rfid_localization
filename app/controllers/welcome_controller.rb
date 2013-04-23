class WelcomeController < ApplicationController
  def index
    parser_data = Parser.parse
    work_zone = WorkZone.new

    @trilateration = Trilateration.new work_zone, parser_data
    @knn = KNearestNeighbours.new work_zone, parser_data


    @k_graph = [[], []]
    ([0, 1]).each do |weighted|
      (1..20).each do |k|
        @k_graph[weighted].push([k, KNearestNeighbours.new(work_zone, parser_data, k, weighted).average_error])
      end
    end
    @k_graph = @k_graph.to_json

  end
end