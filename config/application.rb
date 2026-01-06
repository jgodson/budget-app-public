require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BudgetApp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Configure Prometheus DirectFileStore for multi-process servers (Puma)
    # This must be set before any metrics are initialized
    if Rails.env.production?
      require 'prometheus/client/data_stores/direct_file_store'

      # Set up the directory for Prometheus metrics files
      prometheus_dir = ENV.fetch('PROMETHEUS_MULTIPROC_DIR', Rails.root.join('tmp/prometheus_multiproc'))

      # Create the directory if it doesn't exist
      FileUtils.mkdir_p(prometheus_dir)

      # Configure DirectFileStore (must be before config/initializers run)
      Prometheus::Client.config.data_store = Prometheus::Client::DataStores::DirectFileStore.new(dir: prometheus_dir)

      # Clean up old metrics files from previous runs (must be done before forking)
      config.before_initialize do
        Dir.glob(File.join(prometheus_dir, '*.bin')).each do |file|
          File.delete(file)
        end
      end
    end
  end
end
