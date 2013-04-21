class WelcomeController < ApplicationController
  def index
    @parser_data = Parser.parse
    @work_zone = WorkZone.new

    @localization_method = Trilateration.new @work_zone, @parser_data
  end
end