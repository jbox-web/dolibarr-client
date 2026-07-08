# frozen_string_literal: true

module Dolibarr
  # Supplier invoices — read-only. Returns normalised hashes (amounts coerced to
  # BigDecimal); no dedicated value object, per the working-set scope.
  class SupplierInvoices < Resource
    # One page of supplier invoices as normalised hashes.
    #
    # @param thirdparty_id [Integer, String, nil] restrict to a supplier
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
        '/supplierinvoices',
        'sortfield' => sortfield, 'sortorder' => sortorder,
        'limit' => limit, 'page' => page,
        'thirdparty_ids' => thirdparty_id, 'status' => status, 'sqlfilters' => sqlfilters
      ).map { |raw| Coerce.amounts(raw) }
    end

    # Every matching supplier invoice, paginating transparently. Enumerator when no block.
    def each(limit: 100, **filters, &block)
      enum = paginate(limit: limit) { |page, lim| list(page: page, limit: lim, **filters) }
      block ? enum.each(&block) : enum
    end

    # @return [Array<Hash>]
    def all(**filters)
      each(**filters).to_a
    end

    # Fetch a single supplier invoice by id.
    #
    # @param id [Integer, String]
    # @return [Hash] normalised payload
    # @raise [Dolibarr::Client::NotFound] on 404
    def find(id:)
      Coerce.amounts(get_one("/supplierinvoices/#{encode(id)}", "supplier invoice #{id}"))
    end
  end
end
