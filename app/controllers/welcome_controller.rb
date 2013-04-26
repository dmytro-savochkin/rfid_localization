class WelcomeController < ApplicationController
  def index
    @algorithms = {}

    @algorithms[:trilateration] = Trilateration.new.set_settings.output
    @algorithms[:knn] = KNearestNeighbours.new.set_settings.output


    @algorithms[:knn].make_k_graph
  end


  private

end