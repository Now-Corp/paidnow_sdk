module PaidnowSdk
  # The shape PaidNow's tradee-data endpoint expects. The host application maps
  # its own records into these six sections; this object owns the knowledge of
  # which sections exist and refuses to send an incomplete body.
  class TradeePayload
    SECTIONS = %i[tradee business invoice bank_details address strata_manager].freeze

    attr_reader :sections

    def initialize(sections)
      @sections = symbolize(sections)
      validate!
    end

    def to_h
      SECTIONS.each_with_object({}) { |section, out| out[section] = sections[section] }
    end
    alias to_hash to_h

    private

    def validate!
      missing = SECTIONS.reject { |section| sections[section].is_a?(Hash) }
      return if missing.empty?

      raise InvalidPayload, "tradee payload is missing section(s): #{missing.join(', ')}"
    end

    def symbolize(hash)
      raise InvalidPayload, 'tradee payload must be a Hash' unless hash.respond_to?(:transform_keys)

      hash.transform_keys(&:to_sym)
    end
  end
end
