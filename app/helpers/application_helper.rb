module ApplicationHelper
  def select_tag_for_comparing_algorithms(select_name, algorithms, number_to_select = 0)
    algorithm_to_select = algorithms.keys[number_to_select]
    select_tag select_name.to_s, options_for_select(algorithms.keys, algorithm_to_select)
  end

  def select_tag_with_test_train_heights
    data = []
    (1..4).each do |test_height_number|
      (1..4).each do |train_height_number|
        data.push(test_height_number.to_s + '-' + train_height_number.to_s)
      end
    end
    select_tag 'algorithm_heights_select', options_for_select(data, '4-1')
  end

  def max_antennae_count(tags_reads_by_antennae_count)
    tags_reads_by_antennae_count.values.map{|a| a.select{|k,v|v!=0}.keys.max}.max
  end
end
