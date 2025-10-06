namespace :onboarding do
  desc "Create onboarding records for organizations that don't have one"
  task create_missing: :environment do
    organizations_without_onboarding = Organization.left_joins(:onboarding)
                                                   .where(onboardings: { id: nil })

    count = 0
    organizations_without_onboarding.each do |org|
      org.create_onboarding!
      count += 1
      puts "Created onboarding for organization: #{org.name} (#{org.id})"
    end

    puts "\nCreated #{count} onboarding record(s)"
  end

  desc "List all organizations and their onboarding status"
  task list: :environment do
    Organization.includes(:onboarding).each do |org|
      status = if org.onboarding.nil?
                 "❌ No onboarding"
      elsif org.onboarding.complete?
                 "✅ Complete (#{org.onboarding.progress_percentage}%)"
      else
                 "🔄 In progress (#{org.onboarding.progress_percentage}%)"
      end

      puts "#{org.name}: #{status}"
      if org.onboarding && !org.onboarding.complete?
        puts "  → Access at: /onboardings/#{org.onboarding.id}"
      end
    end
  end
end
