#!/usr/bin/env ruby

require "#{__dir__}/utils"

announce_section "Commit changes?"

commit_changes = ask_boolean "Would you like to commit the changes to your project?", "y"
if commit_changes
  # Get the app name from git config or ask for it
  app_name = `git config --local --get user.appname 2>/dev/null`.strip
  if app_name.empty?
    # Try to extract from the current directory name or recent changes
    app_name = File.basename(Dir.pwd).gsub(/[-_]/, " ").split.map(&:capitalize).join(" ")
  end

  commit_message = if app_name.empty?
    "Configure repository for new application"
  else
    "Configure repository for #{app_name}"
  end

  puts "Committing all these changes to the repository.".green
  stream "git add -A"
  stream "git commit -m \"#{commit_message}\n\n- Update application name and branding throughout codebase\n- Configure Kamal deployment settings\n- Update Docker registry and deployment configuration\n- Generate new Rails credentials for security\""
else
  puts ""
  puts "Make sure you save your changes with Git.".yellow
  puts "Run 'git add -A && git commit -m \"Configure repository for new application\"' when ready.".blue
end
