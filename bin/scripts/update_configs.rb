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
