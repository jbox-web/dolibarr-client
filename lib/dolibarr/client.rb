# frozen_string_literal: true

module Dolibarr
  # The business-facing Dolibarr client. One instance targets one Dolibarr
  # instance; there is no global singleton, so several may coexist.
  #
  # Configuration is read from the environment by default — `DOLIBARR_BASE_URL`
  # and `DOLAPIKEY` — and may be overridden per instance.
  #
  # @example
  #   dolibarr = Dolibarr::Client.new                       # from ENV
  #   dolibarr = Dolibarr::Client.new(                      # explicit
  #     base_url: "https://erp.example.com/api/index.php",
  #     token:    "xxxxxxxx",
  #   )
  #
  # @note Business domains (invoices, payments, thirdparties, documents, supplier
  #   invoices) are layered on top of the {https://github.com/jbox-web/dolibarr-api
  #   dolibarr-api} transport. They are wired in once that dependency lands; this
  #   class currently owns configuration and the single error surface
  #   ({Dolibarr::Client::Error}).
  class Client
    # Environment variable holding the Dolibarr API base URL
    # (e.g. `https://erp.example.com/api/index.php`).
    ENV_BASE_URL = 'DOLIBARR_BASE_URL'
    # Environment variable holding the Dolibarr API key (sent as the `DOLAPIKEY` header).
    ENV_TOKEN    = 'DOLAPIKEY'

    # @return [String] the Dolibarr API base URL
    attr_reader :base_url

    # @param base_url [String] Dolibarr API base URL; defaults to ENV["DOLIBARR_BASE_URL"]
    # @param token [String] Dolibarr API key; defaults to ENV["DOLAPIKEY"]
    # @raise [Dolibarr::Client::Error] if the base URL or token is missing
    def initialize(base_url: ENV.fetch(ENV_BASE_URL, nil), token: ENV.fetch(ENV_TOKEN, nil))
      @base_url = require_config!(base_url, ENV_BASE_URL)
      @token    = require_config!(token, ENV_TOKEN)
    end

    # The underlying dolibarr-api transport client. Lazily built and memoised, one per
    # instance (no global state). The token is handed to the transport as `api_key`
    # (the auth scheme the spec declares).
    #
    # @return [Dolibarr::Api::Client]
    def transport
      @transport ||= Dolibarr::Api::Client.new(base_url: @base_url, api_key: @token)
    end

    # The raw transport connection — the single HTTP choke-point domains call through
    # (with `type: nil`) to sidestep the transport's placeholder typed models.
    #
    # @return [Dolibarr::Api::Connection]
    def connection
      transport.connection
    end

    # @return [Dolibarr::Invoices] customer invoices domain
    def invoices
      @invoices ||= Invoices.new(self)
    end

    # @return [Dolibarr::Payments] payments domain
    def payments
      @payments ||= Payments.new(self)
    end

    # @return [Dolibarr::Thirdparties] thirdparties domain
    def thirdparties
      @thirdparties ||= Thirdparties.new(self)
    end

    # @return [Dolibarr::Documents] documents domain
    def documents
      @documents ||= Documents.new(self)
    end

    # @return [Dolibarr::SupplierInvoices] supplier invoices domain (read-only)
    def supplier_invoices
      @supplier_invoices ||= SupplierInvoices.new(self)
    end

    # @return [Dolibarr::RecurringInvoices] recurring/template invoices domain
    #   (read-only: Dolibarr 23.0.3 exposes no write endpoint for templates).
    def recurring_invoices
      @recurring_invoices ||= RecurringInvoices.new(self)
    end

    private

    def require_config!(value, env_key)
      return value unless value.nil? || value.to_s.empty?

      raise Error, "missing Dolibarr configuration: pass it explicitly or set #{env_key}"
    end
  end
end
