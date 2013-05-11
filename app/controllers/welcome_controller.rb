class WelcomeController < ApplicationController
  def index
    @algorithms = {}



    # рассматривать в статье два случая: 1) только зоны; 2) комбинационный


    #TODO: make a smart combinational algorithm (with "smart" estimating)
    # neural networks, SVMs
    # maybe try to create one RSS-table from data at some height?

    # make adaptive combinational algorithm depending on count of antennae received answers from tags

    # TODO: make greyscale version



    @algorithms_to_compare = []

    height = 41
    powers_to_sizes = {
      20 => [120, 75],
      21 => [120, 75],
      22 => [120, 75],
      23 => [120, 75]
    }
    input = {}

    (20..23).each do |reader_power|
      input[reader_power] = {
          :work_zone => WorkZone.new,
          :tags => Parser.parse(height, reader_power).values.first.values.first.values.first
      }


      algorithm_name = 'zonal_'+reader_power.to_s
      #@algorithms_to_compare.push algorithm_name
      @algorithms[algorithm_name] =
          Algorithm::Zonal.new(input[reader_power], algorithm_name, false).
          set_settings(*powers_to_sizes[reader_power], :adaptive, :ellipses).output


      rss_table = Parser.parse(41, reader_power).values.first.values.first.values.first

      algorithm_name = 'wknn_rss_'+reader_power.to_s
      #@algorithms_to_compare.push algorithm_name
      @algorithms[algorithm_name] =
          Algorithm::Knn.new(input[reader_power], algorithm_name, false).set_settings(:rss, 8, true).output

      algorithm_name = 'wknn_rr_'+reader_power.to_s
      #@algorithms_to_compare.push algorithm_name
      @algorithms[algorithm_name] =
          Algorithm::Knn.new(input[reader_power], algorithm_name, false).set_settings(:rr, 10, true).output

      algorithm_name = 'tri_'+reader_power.to_s
      #@algorithms_to_compare.push algorithm_name
      @algorithms[algorithm_name] =
          Algorithm::Trilateration.new(input[reader_power], algorithm_name, false).set_settings(5).output
    end




    names_to_combinational = ['zonal_20', 'zonal_21', 'zonal_22', 'zonal_23']
    @algorithms_to_compare.push 'zonal'
    @algorithms['zonal'] = Algorithm::Combinational.new(input[22], 'zonal').set_settings(
        names_to_combinational.map {|name| @algorithms[name].map}
    ).output

    names_to_combinational2 = ['wknn_rss_20', 'wknn_rss_21', 'wknn_rss_22', 'wknn_rss_23']
    @algorithms_to_compare.push 'K-NN_RSS'
    @algorithms['K-NN_RSS'] = Algorithm::Combinational.new(input[22], 'K-NN_RSS').set_settings(
        names_to_combinational2.map {|name| @algorithms[name].map}
    ).output

    names_to_combinational2 = ['wknn_rr_20', 'wknn_rr_21', 'wknn_rr_22', 'wknn_rr_23']
    @algorithms_to_compare.push 'K-NN_RR'
    @algorithms['K-NN_RR'] = Algorithm::Combinational.new(input[22], 'K-NN_RR').set_settings(
        names_to_combinational2.map {|name| @algorithms[name].map}
    ).output

    names_to_combinational2 = ['tri_20', 'tri_21', 'tri_22', 'tri_23']
    @algorithms_to_compare.push 'tri_comb'
    @algorithms['trilateration'] = Algorithm::Combinational.new(input[22], 'trilateration').set_settings(
        names_to_combinational2.map {|name| @algorithms[name].map}
    ).output


    #@algorithms[:tri] = Algorithm::Trilateration.new(input[22]).set_settings(5).output

    #@algorithms[:wknn_rss] = Algorithm::Knn.new(input[22]).set_settings(:rss, 8, true).output
    #@algorithms[:wknn_rr] = Algorithm::Knn.new(input[22]).set_settings(:rr, 10, true).output
    #@algorithms[:zonal_rectangles] = Algorithm::Zonal.new(input[20]).set_settings(*sizes, :rectangles).output




    #@algorithms[:zonal_wknn_20] = Algorithm::Combinational.new(input[22]).set_settings(
    #    [@algorithms['wknn_rss20'].map, @algorithms[:zonal].map]
    #).output

    #@algorithms[:combo1] = Algorithm::Combinational.new(input[22], false).set_settings(
    #    [@algorithms[:wknn_rss].map, @algorithms[:zonal].map]
    #).output




    weights = {
        1 => [0.8, 0.2, 0],
        2 => [0.5, 0.2, 0.3],
        3 => [0.33, 0.33, 0.33],
        4 => [0.2, 0.5, 0.3],
        5 => [0.33, 0.33, 0.33],
        6 => [0.33, 0.33, 0.33]
    }

    @algorithms['combined'] = Algorithm::Combinational.new(input[22], 'combined').set_settings(
        [@algorithms['zonal'].map, @algorithms['K-NN_RSS'].map, @algorithms['K-NN_RR'].map],
        weights
    ).output



    #@k_graph_data = Algorithm::Knn.make_k_graph(input, :rss, (1..17))


    @answers_count_by_antennae = calc_answers_count_by_antennae
    calc_best_matches_distribution
  end








  def rr_graphs
    @data = Parser.parse_tag_lines_data
  end











  private

  def calc_best_matches_distribution
    Tag.tag_ids.each do |tag_id|
      antennae_count_tag_answered_to = find_algorithms_with_tag(tag_id).map[tag_id][:answers_count]
      answers_for_antennae_count = @answers_count_by_antennae[antennae_count_tag_answered_to]

      errors_for_algorithms = {}
      @algorithms.select{|name,a| @algorithms_to_compare.include? name}.each do |algorithm_name, algorithm|
        errors_for_algorithms[algorithm_name] = algorithm.map[tag_id][:error] unless algorithm.map[tag_id].nil?
        algorithm.best_suited_for[antennae_count_tag_answered_to][:total] = answers_for_antennae_count
      end
      algorithm_with_min_mean_error = @algorithms[errors_for_algorithms.min_by{|k,v| v}.first]





      algorithm_with_min_mean_error.best_suited_for[antennae_count_tag_answered_to][:percent] +=
          1.0 / algorithm_with_min_mean_error.best_suited_for[antennae_count_tag_answered_to][:total]
      algorithm_with_min_mean_error.best_suited_for[:all][:percent] +=
          1.0 / algorithm_with_min_mean_error.best_suited_for[:all][:total]
    end


    #puts @algorithms.map {|k,v| [k, v.best_matched_count]}.to_yaml
  end

  def calc_answers_count_by_antennae
    hash = {}
    (1..16).each do |antennae_count|
      hash[antennae_count] = @algorithms.first[1].tags.select{|k,tag| tag.answers_count == antennae_count}.size
    end
    hash
  end

  def find_algorithms_with_tag(tag_id)
    @algorithms.each do |algorithm_name, algorithm|
      return algorithm unless algorithm.map[tag_id].nil?
    end
    0
  end


end