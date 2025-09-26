#!/usr/bin/env ruby
# frozen_string_literal: true

require "#{__dir__}/utils"

announce_section "Update project configs"

human = ask "What is the name of your new application in title case? (e.g. \"Some Great Application\")"
while human == ""
  puts "You must provide a name for your application.".red
  human = ask "What is the name of your new application in title case? (e.g. \"Some Great Application\")"
end

require "active_support/inflector"

# new_app_name
variable = ActiveSupport::Inflector.parameterize(human.tr("-", " "), separator: "_")
# NEW_APP_NAME
environment_variable = ActiveSupport::Inflector.parameterize(human.tr("-", " "), separator: "_").upcase
# NewAppName
class_name = variable.classify
# new-app-name
kebab_case = variable.tr("_", "-")
# newappname
connected_name = variable.delete("_")
# New-App-Name
http_header_style = ActiveSupport::Inflector.parameterize(human.tr("_", " "), separator: "-").titleize.tr(" ", "-")

puts ""
puts "Replacing instances of \"Saas Starter\" with \"#{human}\" throughout the codebase.".green
replace_in_file("./config/application.rb", "SaasStarter", class_name)
replace_in_file("./config/deploy.yml", "saas_starter", variable)
replace_in_file("./Dockerfile", "saas_starter", variable)
replace_in_file("./app/views/shared/_footer.html.erb", "SaaS Starter", human)
replace_in_file("./app/views/shared/_navbar.html.erb", "SaaS Starter", human)
replace_in_file("./app/views/layouts/application.html.erb", "SaaS Starter", human)
replace_in_file("./app/views/pwa/manifest.json.erb", "SaasStarter", class_name)
replace_in_file("./CLAUDE.md", "SaaS starter", human)

puts ""

# Deployment configuration
announce_section "Configure deployment settings"

puts "Now let's configure your deployment settings for production.".green
puts "You can skip any of these by pressing Enter, and configure them later.".yellow

# Docker registry username
docker_username = ask "What's your Docker registry username? (Docker Hub, GitHub Container Registry, etc.)"
while docker_username == ""
  puts "You must provide a Docker registry username for deployment.".red
  puts "Examples: 'your-dockerhub-username', 'ghcr.io/your-github-username'".blue
  docker_username = ask "What's your Docker registry username?"
end

# Production domain (optional)
production_domain = ask "What's your production domain? (e.g., 'myapp.com' or press Enter to configure later)"

# Server IP (optional)
server_ip = ask "What's your production server IP address? (or press Enter to configure later)"

# Update Kamal deployment configuration
puts ""
puts "Updating deployment configuration...".green

# Update Docker image references
replace_in_file("./config/deploy.yml", "your-user/saas_starter", "#{docker_username}/#{variable}")
replace_in_file("./config/deploy.yml", "your-user", docker_username)

# Update volume name to match new app name
replace_in_file("./config/deploy.yml", "saas_starter_storage", "#{variable}_storage")

# Update production domain if provided
if production_domain != ""
  replace_in_file("./config/deploy.yml", "app.example.com", production_domain)
  puts "✓ Updated production domain to #{production_domain}".green
else
  puts "⚠ Remember to update 'app.example.com' in config/deploy.yml later".yellow
end

# Update server IP if provided
if server_ip != ""
  replace_in_file("./config/deploy.yml", "192.168.0.1", server_ip)
  puts "✓ Updated server IP to #{server_ip}".green
else
  puts "⚠ Remember to update '192.168.0.1' in config/deploy.yml later".yellow
end

# Optional cleanup and security
announce_section "Security and cleanup"

# Ask about generating new Rails master key
generate_new_key = ask_boolean "Generate a new Rails master key? (recommended for new applications)", "y"
if generate_new_key
  puts "Generating new Rails master key...".green
  # Remove old credentials and master key
  if File.exist?("./config/master.key")
    File.delete("./config/master.key")
    puts "✓ Removed old master key".green
  end
  if File.exist?("./config/credentials.yml.enc")
    File.delete("./config/credentials.yml.enc")
    puts "✓ Removed old encrypted credentials".green
  end

  # Generate new credentials
  stream "bin/rails credentials:edit"
  puts "✓ Generated new Rails credentials".green
  puts "⚠ Make sure to configure your OAuth and Stripe keys in the new credentials file".yellow
else
  puts "⚠ Using existing Rails master key - make sure it's appropriate for your new app".yellow
end

# Ask about cleaning up example files
cleanup_examples = ask_boolean "Remove example configuration files?", "n"
if cleanup_examples
  example_files = [
    "./config/credentials.example.yml",
    "./bin/configure",
    "./bin/scripts"
  ]

  example_files.each do |file|
    if File.exist?(file)
      if File.directory?(file)
        require "fileutils"
        FileUtils.rm_rf(file)
        puts "✓ Removed #{file} directory".green
      else
        File.delete(file)
        puts "✓ Removed #{file}".green
      end
    end
  end
else
  puts "⚠ Example files kept - you may want to remove them before production".yellow
end

puts ""
