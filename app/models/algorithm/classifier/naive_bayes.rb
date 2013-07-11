class Algorithm::Classifier::NaiveBayes < Algorithm::Classifier::Classifier

  private


  def train_model
    bayes_models = {}

    @tags_for_table.values.each do |tag|
      nearest_antenna_number = tag.nearest_antenna.number
      (1..16).each do |antenna_number|
        bayes_models[antenna_number] ||= NBayes::Base.new
        answer = tag.answers[@metric_name][:average][antenna_number] || @mi_class.default_value
        if answer != @mi_class.default_value
          bayes_models[antenna_number].train( [answer], nearest_antenna_number )
        else
          bayes_models[antenna_number].train( [answer], nil )
        end
      end
    end

    bayes_models
  end











  def model_run_method(models, tag)
    data = tag_answers(tag)
    model_probabilities, probable_antennae = calc_models_and_probable_antennae(models, data)

    if probable_antennae.empty?
      find_most_probable_antenna(model_probabilities)
    elsif probable_antennae.length == 1
      probable_antennae.first
    else
      recalculate_probabilities(model_probabilities, probable_antennae)
    end
  end





  def calc_models_and_probable_antennae(models, data)
    model_probabilities = {}
    probable_antennae = []

    (1..16).each do |model_antenna|
      model = models[model_antenna]
      model_probabilities[model_antenna] = model.classify([data[model_antenna - 1]])
      model_most_probable_antenna = model_probabilities[model_antenna].max_class
      probable_antennae.push model_antenna if model_most_probable_antenna == model_antenna
    end

    [model_probabilities, probable_antennae.reject{|a| a.nil?}]
  end





  # find one most probable antenna
  def find_most_probable_antenna(model_probabilities)
    probable_antennae = {}
    (1..16).each do |antenna_number|
      nil_value = model_probabilities[antenna_number].values.max
      normalized_probabilities = normalize(model_probabilities[antenna_number], nil_value)
      cleared_normalized_probabilities = normalized_probabilities.except(nil)
      normalized_probability = cleared_normalized_probabilities[antenna_number]
      probable_antennae[antenna_number] = normalized_probability
    end
    probable_antennae.key(probable_antennae.values.max)
  end

  def normalize(hash, normalize_to)
    hash.map{ |k,v| {k => v / normalize_to} }.reduce(:merge)
  end








  #
  # Recalculate antennae probabilities through models of others most probable antennae
  #
  # a = probable_antennae = [a_1, a_2, ... a_n]
  # M = model_probabilities
  # p = output = [p_1, p_2, ... p_n]
  #
  # p(i) = П( M[i][i] / M[i][j] )
  # where П is miltiplication by j = [1;i)(i;n]
  #
  # Example:
  #
  # probable_antennae: [10, 14]
  # model_probabilities[10]:
  # {
  #   nil=>0.13147660571786907,
  #   5=>0.10954330596755167,
  #   9=>0.10954330596755167,
  #   10=>0.13231911033631943,
  #   6=>0.11575048440951638,
  #   11=>0.10954330596755167,
  #   14=>0.10328462868445341,
  #   13=>0.09022552865987145,
  #   15=>0.09831372428931533
  # }
  # model_probabilities[14]:
  # {
  #   nil=>0.17815386306850495,
  #   9=>0.1608663838130191,
  #   14=>0.19901153774374078,
  #   13=>0.15419728863394605,
  #   10=>0.13633508428910524,
  #   15=>0.17143584245168383
  # }
  # output: {10=>1.2811113524023963, 14=>1.45972358312206}
  #
  def recalculate_probabilities(model_probabilities, probable_antennae)
    antennae = {}
    absent_probability_divider = 10
    significance_ratio = 0.4
    (1..16).each do |antenna_number|
      antenna = model_probabilities[antenna_number].max_class

      if antenna != nil
        probability = model_probabilities[antenna][antenna]

        if (probability / model_probabilities[antenna][nil]) > significance_ratio
          antennae[antenna] ||= 0.0

          recalculated_probability = 1.0
          (probable_antennae - [antenna]).each do |a|
            other_antenna_prob = begin
              probability / model_probabilities[antenna][a]
            rescue
              probability / (model_probabilities[antenna].values.min / absent_probability_divider)
            end
            recalculated_probability *= other_antenna_prob
          end

          antennae[antenna] = recalculated_probability if recalculated_probability > antennae[antenna]
        end
      end
    end

    antennae.key(antennae.values.max)
  end






end