class WelcomeController < ApplicationController
  def index
    @algorithms = {}

    # TODO:
    #
    # - make a smart combinational algorithm (with "smart" estimating)
    # - neural networks, SVMs
    # - make adaptive combinational algorithm which depends on the count of antennae
    # which were used for receiving tags answers
    # - make greyscale version for flot
    # - caching
    # - make a possibility for displaying graph with circles (RSS to radii, etc.)
    # - find out the way to clean MI
    # - calibration for antennae (which antennae can be trusted more for results)


    @algorithms_to_compare = []

    height = 41

    input = {}
    rss_table = {}

    reader_powers = (22..22)
    reader_powers.each do |reader_power|
      input[reader_power] = {
          :work_zone => WorkZone.new,
          :tags => Parser.parse(height, reader_power).values.first.values.first.values.first
      }

=begin
      sizes = [400, 200]
      algorithm_name = 'zonal_rectangles' + reader_power.to_s
      @algorithms[algorithm_name] =
          Algorithm::Zonal.new(input[reader_power], algorithm_name).
          set_settings(*sizes, :average, :rectangles).output

      algorithm_name = 'zonal_ellipses' + reader_power.to_s
      @algorithms[algorithm_name] =
          Algorithm::Zonal.new(input[reader_power], algorithm_name).
          set_settings(*sizes, :average, :ellipses).output
=end

=begin
      rss_table[reader_power] = Parser.parse(41, reader_power).values.first.values.first.values.first


      algorithm_name = 'wknn_rr_' + reader_power.to_s
      algorithm_show_options = {:main => false, :histogram => false}
      algorithm_show_options = {:main => true, :histogram => false} if [22, 25, 28].include? reader_power
      @algorithms[algorithm_name] =
          Algorithm::Knn.new(input[reader_power], algorithm_name, algorithm_show_options).
          set_settings(:rr, 10, true, rss_table[reader_power]).output

      algorithm_name = 'wknn_rss_' + reader_power.to_s
      algorithm_show_options = {:main => false, :histogram => false}
      @algorithms[algorithm_name] =
          Algorithm::Knn.new(input[reader_power], algorithm_name, algorithm_show_options).
          set_settings(:rss, 10, true, rss_table[reader_power]).output
=end
    end

=begin
    algorithm_name = 'wknn_rr_sum'
    @algorithms[algorithm_name] =
        Algorithm::Knn.new(input['sum'], algorithm_name).
        set_settings(:rr, 10, true, rss_table['sum']).output

    algorithm_name = 'wknn_rr_prod'
    @algorithms[algorithm_name] =
        Algorithm::Knn.new(input['prod'], algorithm_name, {:main => true, :histogram => false}).
        set_settings(:rr, 10, true, rss_table['prod']).output


    names_to_combinational2 = ['wknn_rr_20', 'wknn_rr_21', 'wknn_rr_22', 'wknn_rr_23', 'wknn_rr_24']
    algorithm_name = 'wknn_rr_comb'
    @algorithms_to_compare.push algorithm_name
    @algorithms[algorithm_name] =
      Algorithm::Combinational.new(input[22], algorithm_name, {:main => false, :histogram => false}).
      set_settings(names_to_combinational2.map {|name| @algorithms[name].map}).output

    names_to_combinational2 = ['wknn_rss_20', 'wknn_rss_21', 'wknn_rss_22', 'wknn_rss_23', 'wknn_rss_24']
    algorithm_name = 'wknn_rss_comb'
    @algorithms[algorithm_name] =
      Algorithm::Combinational.new(input[22], algorithm_name, {:main => true, :histogram => true}).
      set_settings(names_to_combinational2.map {|name| @algorithms[name].map}).output
=end

    step = 100
    @algorithms['tri1'] = Algorithm::TrilaterationMaxProbability.new(input[22], 'tri1').set_settings(step).output
    @algorithms['tri2'] = Algorithm::TrilaterationLeastSquares.new(input[22], 'tri2').set_settings(step).output

    #@algorithms[:wknn_rss] = Algorithm::Knn.new(input[22]).set_settings(:rss, 8, true).output
    #@algorithms[:wknn_rr] = Algorithm::Knn.new(input[22]).set_settings(:rr, 10, true).output




    #@algorithms[:zonal_wknn_20] = Algorithm::Combinational.new(input[22]).set_settings(
    #    [@algorithms['wknn_rss20'].map, @algorithms[:zonal].map]
    #).output

    #@algorithms[:combo1] = Algorithm::Combinational.new(input[22], false).set_settings(
    #    [@algorithms[:wknn_rss].map, @algorithms[:zonal].map]
    #).output




    #@algorithms['combined'] = Algorithm::Combinational.new(input[22], 'combined').set_settings(
    #    [@algorithms['zonal'].map, @algorithms['K-NN_RSS'].map, @algorithms['K-NN_RR'].map],
    #    weights
    #).output



    #@k_graph_data = Algorithm::Knn.make_k_graph(input, :rss, (1..17))



    @answers_count_by_antennae = calc_answers_count_by_antennae
    #calc_best_matches_distribution
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