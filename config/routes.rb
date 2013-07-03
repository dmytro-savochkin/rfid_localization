Rfid::Application.routes.draw do
  match 'rr' => 'main#rr_graphs'
  match 'correlation' => 'main#rss_rr_correlation'

  root :to => 'main#main'
end
