# frozen_string_literal: true

require 'base64'

module Dolibarr
  # Documents: fetch generated files from Dolibarr's document store.
  #
  # Dolibarr's `GET /documents/download` returns the file as a JSON envelope with the
  # bytes base64-encoded (not a raw binary stream), so this decodes and writes them.
  class Documents < Resource
    # Modulepart Dolibarr uses for customer invoices in its document store.
    INVOICE_MODULEPART = 'facture'

    # Download a customer invoice's PDF to a local path.
    #
    # The PDF must already have been generated in Dolibarr (validating the invoice, or
    # opening it in the UI, builds it); if it has not, Dolibarr answers 404 and this
    # raises {Dolibarr::Client::NotFound}.
    #
    # @param ref [String] the invoice reference (e.g. "FA2601-0007")
    # @param to [String] destination file path
    # @return [String] the destination path written
    # @raise [Dolibarr::Client::NotFound] when the PDF does not exist yet
    # @raise [Dolibarr::Client::Error] when the response carries no content
    def download_invoice_pdf(ref:, to:)
      envelope = get_one(
        '/documents/download', "PDF for invoice #{ref}",
        'modulepart' => INVOICE_MODULEPART, 'original_file' => "#{ref}/#{ref}.pdf"
      )

      content = envelope['content']
      raise Client::Error, "download response for #{ref} carried no content" if content.nil?

      bytes = envelope['encoding'].to_s == 'base64' ? Base64.decode64(content) : content
      File.binwrite(to, bytes)
      to
    end
  end
end
