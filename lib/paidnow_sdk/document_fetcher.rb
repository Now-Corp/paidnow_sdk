require 'http'

module PaidnowSdk
  # Downloads a PaidNow-hosted document and proves it really is a PDF before the
  # host application does anything durable with the bytes.
  class DocumentFetcher
    class DownloadFailed < Error; end
    class InvalidContent < Error; end

    PDF_MAGIC_BYTES = '%PDF-'.freeze

    attr_reader :config

    def initialize(config: PaidnowSdk.config)
      @config = config
    end

    # Returns the raw bytes. Raises DownloadFailed (worth retrying) or
    # InvalidContent (not worth retrying).
    def fetch_pdf(url)
      bytes = download(url)
      validate_pdf!(bytes)
      bytes
    end

    private

    def download(url)
      response = HTTP.timeout(config.timeout).get(url)
      raise DownloadFailed, "document_url returned status #{response.status}" unless response.status.success?

      response.body.to_s
    rescue HTTP::Error => e
      raise DownloadFailed, "Failed to download document: #{e.message}"
    end

    def validate_pdf!(bytes)
      raise InvalidContent, 'Downloaded content is not a valid PDF' unless bytes.byteslice(0, 5) == PDF_MAGIC_BYTES
    end
  end
end
