# config/initializers/prevent_precompiled_assets_in_dev.rb

if Rails.env.development? && Rails.root.join("public/assets").exist?
  raise "Precompiled assets detected in public/assets. This can cause confusing issues in development " \
        "where changes to assets are not picked up.\n\n" \
        "Please run `rails assets:clobber` to remove them."
end
