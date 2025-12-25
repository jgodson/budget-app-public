# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )
Rails.application.config.assets.precompile += %w(bootstrap.min.js popper.js)
Rails.application.config.assets.precompile << "chart.js/dist/chart.umd.js"

# Precompile all Popper.js ESM files
node_modules_path = Rails.root.join("node_modules")
Rails.application.config.assets.precompile += Dir[node_modules_path.join("@popperjs/core/dist/esm/**/*.js")].map do |f|
  f.sub("#{node_modules_path}/", "")
end
Rails.application.config.assets.paths << Rails.root.join("node_modules")
