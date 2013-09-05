Rfid::Application.routes.draw do
  match 'rr' => 'main#rr_graphs'
  match 'correlation' => 'main#rss_rr_correlation'
  match 'regression' => 'main#regression'

  match 'classifier' => 'main#classifier'
  match 'point' => 'main#point_based'

  root :to => 'main#point_based'
end
