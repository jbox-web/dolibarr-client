# frozen_string_literal: true

module Dolibarr
  # Customer invoices — the heart of the monthly working set: list (with period,
  # thirdparty and paid/unpaid filters), fetch by ref or id, create, validate.
  #
  # Reads go through the raw connection with `type: nil` (the transport's typed `get`
  # pins the placeholder `Obj` model and would drop the payload). Empty lists are
  # normalised to `[]`; a missing single invoice raises {Dolibarr::Client::NotFound}.
  class Invoices < Resource
    # One page of invoices as {Invoice} value objects.
    #
    # @param thirdparty_id [Integer, String, nil] restrict to a customer
    # @param status [String, nil] Dolibarr status filter ("draft"/"unpaid"/"paid"/"cancelled")
    # @param paid [Boolean, nil] convenience: maps to the "paid"/"unpaid" status filter
    #   (ignored when `status` is given explicitly)
    # @param from [Date, String, nil] lower bound on the invoice date (inclusive)
    # @param to [Date, String, nil] upper bound on the invoice date (inclusive)
    # @param limit [Integer] page size
    # @param page [Integer] 0-based page index
    # @param sortfield [String] Restler sort field (default "t.rowid")
    # @param sortorder [String] "ASC" / "DESC"
    # @return [Array<Invoice>]
    def list(thirdparty_id: nil, status: nil, paid: nil, from: nil, to: nil,
             limit: 100, page: 0, sortfield: 't.rowid', sortorder: 'ASC')
      raws = get_list(
        '/invoices',
        'sortfield' => sortfield, 'sortorder' => sortorder,
        'limit' => limit, 'page' => page,
        'thirdparty_ids' => thirdparty_id,
        'status' => status || paid_status(paid),
        'sqlfilters' => period_filter(from, to)
      )
      raws.map { |raw| Invoice.from(raw) }
    end

    # Every matching invoice, paginating transparently. Returns an Enumerator when no
    # block is given.
    #
    # @param limit [Integer] page size used while walking
    # @param filters [Hash] any {#list} filter
    # @yieldparam invoice [Invoice]
    # @return [Enumerator, void]
    def each(limit: 100, **filters, &block)
      enum = paginate(limit: limit) { |page, lim| list(page: page, limit: lim, **filters) }
      block ? enum.each(&block) : enum
    end

    # All matching invoices as an Array (auto-paginated).
    # @return [Array<Invoice>]
    def all(**filters)
      each(**filters).to_a
    end

    # Fetch a single invoice by ref or id (exactly one required).
    #
    # @param ref [String, nil] invoice reference (e.g. "FA2601-0007")
    # @param id [Integer, String, nil] invoice rowid
    # @return [Invoice]
    # @raise [ArgumentError] unless exactly one of ref/id is provided
    # @raise [Dolibarr::Client::NotFound] when Dolibarr answers 404
    def find(ref: nil, id: nil)
      raise ArgumentError, 'find requires exactly one of ref: or id:' unless ref.nil? ^ id.nil?

      raw =
        if ref
          get_one("/invoices/ref/#{encode(ref)}", "invoice #{ref}")
        else
          get_one("/invoices/#{encode(id)}", "invoice #{id}")
        end
      Invoice.from(raw)
    end

    # Create an invoice. Attributes are sent as the request body verbatim (Dolibarr's
    # `createInvoicesModel` is a passthrough).
    #
    # @param attributes [Hash] invoice fields (socid, type, lines, …)
    # @return [Integer] the new invoice id returned by Dolibarr
    def create(**attributes)
      call { connection.call(:POST, '/invoices', type: nil, auth: ['api_key'], body: attributes).data }
    end

    # Validate a draft invoice (assigns its definitive ref).
    #
    # @param id [Integer, String] invoice rowid
    # @param notrigger [Integer, nil] 1 to skip business triggers
    # @return [Invoice] the refreshed invoice
    def validate(id:, notrigger: nil)
      raw = call do
        connection.call(
          :POST, "/invoices/#{encode(id)}/validate",
          type: nil, auth: ['api_key'], body: { 'notrigger' => notrigger }.compact
        ).data
      end
      Invoice.from(raw)
    end

    private

    def paid_status(paid)
      return nil if paid.nil?

      paid ? 'paid' : 'unpaid'
    end

    # Builds a Restler sqlfilter on the invoice date (t.datef) from a from/to window.
    def period_filter(from, to)
      clauses = []
      clauses << "(t.datef:>=:'#{iso_date(from)}')" if from
      clauses << "(t.datef:<=:'#{iso_date(to)}')" if to
      clauses.empty? ? nil : clauses.join(' and ')
    end
  end
end
