Rfid::Application.routes.draw do
  match 'rr' => 'main#rr_graphs'
  match 'correlation' => 'main#rss_rr_correlation'
  match 'regression' => 'main#regression'
  match 'regression_rss_graphs' => 'main#regression_rss_graphs'
  match 'response_probabilities' => 'main#response_probabilities'
  match 'deviations' => 'main#deviations'
  match 'rss_time' => 'main#rss_time'

  match 'classifier' => 'main#classifier'
  match 'point' => 'main#point_based'
  match 'point_classifying' => 'main#point_based_with_classifying'

  match 'deployment' => 'main#deployment'

  root :to => 'main#point_based'
end
