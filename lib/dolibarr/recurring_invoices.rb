# frozen_string_literal: true

module Dolibarr
  # Recurring / template invoices ("factures modèles"). Read-only: Dolibarr 23.0.3
  # exposes only GET on `/invoices/templates` — creating a template or triggering a
  # generation is not available over REST (it happens in the UI or the internal cron).
  #
  # Returns normalised hashes (amounts coerced); the generated child invoices surface
  # in the ordinary {Invoices} domain, where the full cycle (validate/pay/close) lives.
  class RecurringInvoices < Resource
    # One page of template invoices as normalised hashes.
    #
    # @param thirdparty_id [Integer, String, nil] restrict to a customer
    # @param status [String, nil] Dolibarr status filter
    # @param sqlfilters [String, nil] raw Restler sqlfilter
    # @param limit [Integer] page size
    # @param page [Integer] 0-based page index
    # @param sortfield [String]
    # @param sortorder [String]
    # @return [Array<Hash>]
    def list(thirdparty_id: nil, status: nil, sqlfilters: nil,
             limit: 100, page: 0, sortfield: 't.rowid', sortorder: 'ASC')
      get_list(
        '/invoices/templates',
        'sortfield' => sortfield, 'sortorder' => sortorder,
        'limit' => limit, 'page' => page,
        'thirdparty_ids' => thirdparty_id, 'status' => status, 'sqlfilters' => sqlfilters
      ).map { |raw| Coerce.amounts(raw) }
    end

    # Every matching template, paginating transparently. Enumerator when no block.
    def each(limit: 100, **filters, &block)
      enum = paginate(limit: limit) { |page, lim| list(page: page, limit: lim, **filters) }
      block ? enum.each(&block) : enum
    end

    # @return [Array<Hash>]
    def all(**filters)
      each(**filters).to_a
    end

    # Fetch a single template invoice by id.
    #
    # @param id [Integer, String]
    # @return [Hash] normalised payload
    # @raise [Dolibarr::Client::NotFound] on 404
    def find(id:)
      Coerce.amounts(get_one("/invoices/templates/#{encode(id)}", "template invoice #{id}"))
    end
  end
end
