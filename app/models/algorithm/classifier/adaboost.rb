class Stump
  attr_accessor :mi_number, :mi_threshold, :zone
  def initialize(mi_number, mi_threshold, zone, sign)
    @mi_number = mi_number.to_i
    @mi_threshold = mi_threshold.to_f
    @zone = zone
    @sign = sign
  end

  def run(tag_answers)
    return false unless tag_answers.keys.include? @mi_number
    return @zone if tag_answers[@mi_number].send(@sign, @mi_threshold)
    false
  end

  def h(tag_answers, output_zone)
    value = 0.9

    confidence = {}
    (1..16).each {|zone| confidence[zone] = 1.0 / 16}

    if tag_answers.keys.include?(@mi_number) and tag_answers[@mi_number].send(@sign, @mi_threshold)
      confidence[@zone] = value
      ((1..16).to_a - [@zone]).each {|zone| confidence[zone] = (1.0 - value) / 15}
    end

    confidence[output_zone]
  end


  def to_s
    'if x[' + @mi_number.to_s + '] ' + @sign.to_s + ' ' + @mi_threshold.to_s + ' then ' + @zone.to_s
  end

end








class Algorithm::Classifier::Adaboost < Algorithm::Classifier

  T = 30

  private

  def train_stump(distribution, q)
    min_total_error = +1.0/0.0
    best_stump = nil
    (1..16).each do |mi_number|
      @mi_class.range.to_a.each do |mi_threshold|
        (1..16).each do |conditional_zone|
          [:>].each do |sign|
            stump = Stump.new(mi_number, mi_threshold, conditional_zone, sign)

            current_total_error = 0.0
            @tags_input.each do |i, tag|
              resulted_zone = stump.run(tag.answers[@metric_name][:average])

              error = (resulted_zone == tag.zone) ? 0.0 : 1.0
              p_error = distribution[i] * error
              #p_error *= q[i][conditional_zone] if q[i][conditional_zone].present?
              current_total_error += p_error
            end

            #puts stump.to_s + '    -----     ' + current_total_error.to_s

            if current_total_error < min_total_error
              min_total_error = current_total_error
              best_stump = stump
            end
          end


        end

      end


    end

    best_stump
  end




  def train_model(tags_train_input)
    distribution = []
    weights = []
    distribution[0] = {}
    weights[0] = {}
    tags_train_input.each do |i, tag|
      distribution[0][i] = 1.0 / tags_train_input.length
      weights[0][i] = {}
      (1..16).each do |g|
        weights[0][i][g] = distribution[0][i] / (16 - 1)
      end
    end


    q = []
    alpha = []
    beta = []
    stumps = []
    (0...T).each do |t|
      q[t] = {}

      weights_sum = {}
      tags_train_input.each do |i, tag|
        q[t][i] = {}

        weights_sum[i] = 0.0
        ((1..16).to_a - [tag.zone]).each do |g|
          weights_sum[i] += weights[t][i][g]
        end
        ((1..16).to_a - [tag.zone]).each do |g|
          q[t][i][g] = weights[t][i][g] / weights_sum[i]
        end
      end

      distribution[t] = {}
      tags_train_input.each do |i, tag|
        distribution[t][i] = weights_sum[i] / weights_sum.values.sum
      end


      puts t.to_s
      #puts 'weights: ' + weights[t].to_s
      #puts 'q: ' + q[t].to_s
      puts 'D: ' + distribution[t].to_s

      puts 'training'
      stumps[t] = train_stump(distribution[t], q[t])
      puts 'training is over'


      puts 'x'
      pseudo_loss = 0.0
      tags_train_input.each do |i, tag|

        other_variants_sum = 0.0
        ((1..16).to_a - [tag.zone]).each do |g|
          other_variants_sum += stumps[t].h(tag.answers[@metric_name][:average], g) * q[t][i][g]
        end

        pseudo_loss += distribution[t][i] * (1.0 - stumps[t].h(tag.answers[@metric_name][:average], tag.zone) + (1.0 / (16-1) * other_variants_sum))
      end
      pseudo_loss *= 0.5
      puts 'x...'

      break if pseudo_loss > 0.5

      puts 'y'
      alpha[t] = 0.5 * Math.log((1.0 - pseudo_loss) / pseudo_loss)
      beta[t] = pseudo_loss / (1.0 - pseudo_loss)

      weights[t+1] = {}
      tags_train_input.each do |i, tag|
        weights[t+1][i] = {}
        ((1..16).to_a - [tag.zone]).each do |g|
          weights[t+1][i][g] =
              weights[t][i][g] *
              (beta[t] ** (0.5 *
              (1.0 + stumps[t].h(tag.answers[@metric_name][:average], tag.zone) - stumps[t].h(tag.answers[@metric_name][:average], g)) ))
        end
        weights[t+1][i][tag.zone] = weights[t][i][tag.zone]
      end
      puts 'y...'



      puts t.to_s + ' beta: ' + beta[t].to_s + '. Stump: ' + stumps[t].to_s
      puts ''
    end


    stumps.each_with_index {|stump, i| puts beta[i].to_s + ' _ ' + stump.to_s }
    {beta: beta, stumps: stumps}
  end








  def model_run_method(model, tag)
    max_probability = 0.0
    best_guess = nil
    (1..16).each do |zone|
      total_probability = 0.0
      (0...T).each do |t|
        total_probability += Math.log(1.0 / model[:beta][t]) * model[:stumps][t].h(tag.answers[@metric_name][:average], zone)
      end

      if total_probability > max_probability
        max_probability = total_probability
        best_guess = zone
      end
    end

    best_guess
  end





end