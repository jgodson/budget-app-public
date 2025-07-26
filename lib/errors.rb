module Errors
  class InvalidFileError < StandardError
    def initialize(msg = "Invalid import type provided.")
      super(msg)
    end
  end
end