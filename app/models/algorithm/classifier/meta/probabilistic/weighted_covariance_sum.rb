class Algorithm::Classifier::Meta::Probabilistic::WeightedCovarianceSum < Algorithm::Classifier::Meta::Probabilistic::Sum

  private

  def error_vector(true_probabilities, given_probabilities, zone_number)
    given_probabilities.map do |tag_probabilities_pair|
      tag_name = tag_probabilities_pair.first
      probabilities = tag_probabilities_pair.last
      true_probabilities[tag_name].to_f - probabilities[zone_number].to_f

      #zone_number_is_chosen = (zone_number == probabilities.key(probabilities.values.max))
      #if true_probabilities[tag_name].to_f == 1 and zone_number_is_chosen
      #  0.0
      #elsif true_probabilities[tag_name].to_f == 0 and !zone_number_is_chosen
      #  0.0
      #else
      #  1.0
      #end
    end
  end


  def set_up_model(model, train_data, setup_data, height_index)
    i_matrix = Matrix.build(@algorithms.length, 1){1.0}

    weights = {}
    (1..16).each do |zone_number|
      true_probabilities = Hash[TagInput.tag_ids.map do |tag_id|
        [tag_id, TagInput.new(tag_id).in_zone?(zone_number).to_i]
      end]

      covariances = Matrix.build(@algorithms.length, @algorithms.length)

      @algorithms.values.each_with_index do |algorithm1, index1|
        algorithm1_probabilities = algorithm1[:setup][height_index][:probabilities]
        @algorithms.values.each_with_index do |algorithm2, index2|
          algorithm2_probabilities = algorithm2[:setup][height_index][:probabilities]
          covariances[index1, index2] = Math.covariance(
              error_vector(true_probabilities, algorithm1_probabilities, zone_number),
              error_vector(true_probabilities, algorithm2_probabilities, zone_number)
          )

          #puts error_vector(true_probabilities, algorithm1_probabilities, zone_number).to_s
          #puts error_vector(true_probabilities, algorithm2_probabilities, zone_number).to_s
          #puts covariances[index1, index2].to_s

          #ПРОВЕРИТЬ ЕЩЕ НА ОШИБКИ?
          #попробовать не вносить в вычисление те ошибки, которые получены для малых вероятностей:
          #то есть, если есть одна вероятность 0.9, то нет смысла считать ошибки между 0.3 и 0.0
          #
          #если это не поможет то сделать еще простую версию весовых коэффициентов по проценту
          #правильной классификации без коррелляций (попробовать и по зонам И без зон)
          #по идее это и будет упрощенным вариантом написанного варианта, но только с одной
          # главной вероятностью
          #
          #или еще сделать отдельно чтобы ошибка между векторами
          #0.7 0.2 0.1 0.22
          #и
          #1.0 0.0 0.0 0.0
          #была равна нулю (то есть главное чтобы позиции максимумов совпадали)
          #Проверить, одинаковые ли будут результаты с предыдущим

        end
      end

      # formula from "Combining Pattern Classifiers"
      inversed_covariances = covariances.inverse
      weights[zone_number] = (
          inversed_covariances * i_matrix *
          (i_matrix.transpose * inversed_covariances * i_matrix).inverse
      ).column(0).to_a

      #puts covariances.to_a.to_s
      #puts @weights[zone_number].to_a.to_s
      #puts ''
    end
    weights
  end




  def algorithm_weight(weights, zone_number, algorithm_index)
    weights[zone_number][algorithm_index]
  end


end