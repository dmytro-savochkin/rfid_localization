class Algorithm::Classifier::RandomForest < Algorithm::Classifier

  private

  def save_in_file_by_external_mechanism
    true
  end

  def desired_accuracies(height)
    [0.925, 0.87, 0.925, 0.915][height]
  end

  def train_model(tags_train_input, height)
    if height.is_a? Array
      height = height.first
    end

    desired_accuracy = desired_accuracies(height)

    trees_count = 100
    tags_count_to_use = 60
    antennae_count_to_use = 4

    accuracy = 0.0
    while accuracy < desired_accuracy
      trees = []

      trees_count.times do
        tags_set = []
        tags_count_to_use.times do
          rnd = Random.rand(0...tags_train_input.length)
          tags_set.push tags_train_input.values[rnd]
        end

        antennae_to_use = (1..16).to_a.sample(antennae_count_to_use).sort

        tree = create_tree(tags_set, antennae_to_use)
        trees.push tree
      end

      accuracy = calc_accuracy(trees, tags_train_input)
    end

    trees
  end

  def create_tree(tags, antennae_to_use)
    tree = {:model => nil, :antennae_to_use => antennae_to_use}

    train = []
    tags.each do |tag|
      answers = tag_answers_for_specific_antennae(tag, antennae_to_use)
      train.push(answers + [tag.zone])
    end

    data_set = Ai4r::Data::DataSet.new(
        :data_items => train,
        :data_labels => (1..(antennae_to_use.length + 1)).
            to_a)
    model = Ai4r::Classifiers::ID3.new.build(data_set)
    tree[:model] = model

    tree
  end






  def model_run_method(trees, setup, tag)
    results = []
    trees.each do |tree|
      begin
        answers = tag_answers_for_specific_antennae(tag, tree[:antennae_to_use])
        result = tree[:model].eval(answers)
      rescue Ai4r::Classifiers::ModelFailureError => e
        result = nil
      end
      results.push result
    end

    result_zone = results.reject(&:nil?).mode.first

    {
        :probabilities => {},
        :result_zone => result_zone
    }
  end








  def tag_answers_for_specific_antennae(tag, antennae)
    antennae.map{|antenna| tag.answers[@metric_name][:average][antenna] || @mi_class.default_value }
  end

end