class WelcomeController < ApplicationController
  def index
    @parser_data = Parser.parse
    @work_zone = WorkZone.new

    @trilateration = Trilateration.new @work_zone, @parser_data
    @knn = KNearestNeighbours.new @work_zone, @parser_data
  end
end