namespace :ucsc_sufia_based_dams  do 
  task :stop_resque do
    on roles(:app), in: :sequence, wait: 5 do
      print "Stopping resque-pool..."
      execute "cd '#{release_path}'; sudo stop_resque #{fetch(:stage)}"
    end
  end
  task :start_resque do
    on roles(:app), in: :sequence, wait: 5 do
      print "Starting resque-pool..."
      execute "cd '#{release_path}'; sudo start_resque #{fetch(:stage)}"
    end
  end
end
before "deploy:starting","ucsc_sufia_based_dams:stop_resque"
after "deploy:finished","ucsc_sufia_based_dams:start_resque"
