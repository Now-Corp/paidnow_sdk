module PaidnowSdk
  class Error < StandardError; end

  # Raised when PaidNow answers with a non-2xx status, or the request never
  # completed. Carries the HTTP status when there was one.
  class RequestError < Error
    attr_reader :status

    def initialize(message, status = nil)
      @status = status
      super(message)
    end
  end

  class ConfigurationError < Error; end
  class InvalidPayload < Error; end
end
