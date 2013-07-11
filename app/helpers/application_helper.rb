module ApplicationHelper
  def select_tag_for_comparing_algorithms(select_name, algorithms, number_to_select = 0)
    algorithm_to_select = algorithms.keys[number_to_select]
    select_tag select_name.to_s, options_for_select(algorithms.keys, algorithm_to_select)
  end

  def max_antennae_count(tags_reads_by_antennae_count)
    tags_reads_by_antennae_count.values.map{|a| a.select{|k,v|v!=0}.keys.max}.max
  end
end
