# frozen_string_literal: true

module Dolibarr
  # Thirdparties (customers/suppliers): list and fetch. Reads go through the raw
  # connection (`type: nil`) so the payload survives the transport's placeholder model.
  class Thirdparties < Resource
    # Business-readable {#list} `mode` values → Dolibarr's integer `mode` filter.
    # Dolibarr expects an integer (api_thirdparties.class.php@23.0.3): 1=customers,
    # 2=prospects, 4=suppliers. Codes 0 (all) and 3 (neither customer nor prospect)
    # have no business use here and are intentionally not exposed. Sending the raw
    # label instead of the code makes Dolibarr answer HTTP 400.
    MODE_CODES = { 'customer' => 1, 'prospect' => 2, 'supplier' => 4 }.freeze

    # One page of thirdparties as {Thirdparty} value objects.
    #
    # @param mode [String, Symbol, nil] "customer"/"prospect"/"supplier" (translated to
    #   Dolibarr's integer `mode` filter)
    # @param category [Integer, String, nil] restrict to a category id
    # @param sqlfilters [String, nil] raw Restler sqlfilter
    # @param limit [Integer] page size
    # @param page [Integer] 0-based page index
    # @param sortfield [String]
    # @param sortorder [String]
    # @return [Array<Thirdparty>]
    def list(mode: nil, category: nil, sqlfilters: nil,
             limit: 100, page: 0, sortfield: 't.rowid', sortorder: 'ASC')
      get_list(
        '/thirdparties',
        'sortfield' => sortfield, 'sortorder' => sortorder,
        'limit' => limit, 'page' => page,
        'mode' => mode_code(mode), 'category' => category, 'sqlfilters' => sqlfilters
      ).map { |raw| Thirdparty.from(raw) }
    end

    # Every matching thirdparty, paginating transparently. Enumerator when no block.
    def each(limit: 100, **filters, &block)
      enum = paginate(limit: limit) { |page, lim| list(page: page, limit: lim, **filters) }
      block ? enum.each(&block) : enum
    end

    # @return [Array<Thirdparty>]
    def all(**filters)
      each(**filters).to_a
    end

    # Fetch a single thirdparty by id.
    #
    # @param id [Integer, String]
    # @return [Thirdparty]
    # @raise [Dolibarr::Client::NotFound] on 404
    def find(id:)
      Thirdparty.from(get_one("/thirdparties/#{encode(id)}", "thirdparty #{id}"))
    end

    private

    # Translate a business-readable mode into Dolibarr's integer code, or raise on an
    # unknown value so an invalid filter never reaches the API. `nil` passes through
    # (unfiltered list).
    def mode_code(mode)
      return nil if mode.nil?

      MODE_CODES.fetch(mode.to_s) do
        raise Client::Error,
              "unknown thirdparty mode #{mode.inspect}; expected one of: #{MODE_CODES.keys.join(', ')}"
      end
    end
  end
end
