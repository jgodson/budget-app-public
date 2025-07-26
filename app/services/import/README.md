These services are used to import budget or transaction data

Adding a new one is easy. Create the new file in this directory, and it will be loaded automatically when needed. The service class needs to define two methods (besides a simple `initialize`):

1. `self.service_for_file?(file, model)`
This method determines whether the file should be processed by the service. It should be unique and the file and the model type (Budget or Transaction, generally) is passed in as arguments.

    ```
      class << self
        def service_for_file?(file, model)
          file_name = File.basename(file.original_filename)
          file_name.match?(/Budget (\d{4}) - Budget\.csv/) && model == Budget
        end
      end
    ```

1. `preview`
This method should parse the file the class was initialized with (by the `import_service_loader`) and return an object with two keys:

    ```
    {
      items: [],
      new_categories: []
    }
    ```

    `items` should be everything the model needs to be created as well as two additional things:

    - `status`: There can be a variety of these but the important ones are `:new`, `:ignored`, or `:duplicate`. Only `:new` items will be selected for import by default on the preview form.
    - `unique_id`: This is used on the preview form for changing the category of the item if the pre-selected one. The only requirement is that it is unique among the items.

    `new_categories` should include an initalized `Category` with a `name` and `type` if the category was a new record.

    An example of how to implment this would be:
    
    ```
    category_name = row['Item']

    category = Category.find_or_initialize_by(
      name: category_name, 
      category_type: CategoryTypes::CATEGORY_TYPES[:expense]
    )

    unless preview_data[:new_categories].any? { |c| c.name == category.name }
      preview_data[:new_categories] << category if category.new_record?
    end
    ```

There are classes defined under `shared/transaction_category_patterns.rb` and `shared/transaction_skip_patterns` that can be used when determining whether a transaction can be imported or not. You can either prevent it from being added to the `items` array entirely, or mark it as `:ignored` and allow it to be optionally selected to import on the import preview form.