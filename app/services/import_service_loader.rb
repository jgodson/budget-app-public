class ImportServiceLoader
  SERVICE_FOLDER = 'app/services/import'
  SERVICE_CLASSES = []

  class << self
    def load_services
      Dir[Rails.root.join(SERVICE_FOLDER, '*.rb')].each do |file|
        require_dependency file
        class_name = "Import::#{File.basename(file, '.rb').camelize}"
        service_class = class_name.safe_constantize
        if service_class
          Rails.logger.info("Loaded service class: #{class_name}")
          SERVICE_CLASSES << service_class
        else
          Rails.logger.warn("Failed to load service class: #{class_name}")
        end
      end
    end

    def service_for_file(file, model)
      load_services if SERVICE_CLASSES.empty?

      SERVICE_CLASSES.each do |service_class|
        return service_class.new(file) if service_class.service_for_file?(file, model)
      end

      nil
    end
  end
end