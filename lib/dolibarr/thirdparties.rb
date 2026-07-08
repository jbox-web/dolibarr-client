# frozen_string_literal: true

module Dolibarr
  # Thirdparties (customers/suppliers): list and fetch. Reads go through the raw
  # connection (`type: nil`) so the payload survives the transport's placeholder model.
  class Thirdparties < Resource
    # One page of thirdparties as {Thirdparty} value objects.
    #
    # @param mode [String, nil] "customer"/"supplier"/… (Dolibarr `mode` filter)
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
        'mode' => mode, 'category' => category, 'sqlfilters' => sqlfilters
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
  end
end
