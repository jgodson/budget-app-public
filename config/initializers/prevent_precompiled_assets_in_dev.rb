# config/initializers/prevent_precompiled_assets_in_dev.rb

if Rails.env.development? && Rails.root.join("public/assets").exist?
  # Allow assets:clobber to run
  is_clobbering = defined?(Rake) && Rake.application.top_level_tasks.any? { |task| task.to_s =~ /assets:clobber|assets:clean/ }
  
  unless is_clobbering
    raise "Precompiled assets detected in public/assets. This can cause confusing issues in development " \
          "where changes to assets are not picked up.\n\n" \
          "Please run `rails assets:clobber` to remove them."
  end
end
