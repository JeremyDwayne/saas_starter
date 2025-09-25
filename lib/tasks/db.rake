namespace :db do
  unless Rails.env.development? || Rails.env.test?
    tasks = Rake.application.instance_variable_get :@tasks
    # Enable this when team is larger
    # tasks.delete "db:migrate"
    # desc "db:migrate not available in this environment"
    # task migrate: :environment do
    #   puts "db:migrate not available in this environment, use db:migrate:up VERSION=YYYMMDDHHMMSS"
    # end

    tasks.delete "db:reset"
    desc "db:reset not available in this environment"
    task reset: :environment do
      puts "db:reset has been disabled"
    end

    tasks.delete "db:drop"
    desc "db:drop not available in this environment"
    task drop: :environment do
      puts "db:drop has been disabled"
    end
  end
end
