# frozen_string_literal: true

module Dolibarr
  # Base class for every business domain (invoices, payments, thirdparties, …).
  #
  # It owns the two things every domain shares: reaching the raw transport
  # connection, and funnelling every `dolibarr-api` failure through the single
  # {Dolibarr::Client::Error} surface. Restler quirks are absorbed here:
  #
  # - an empty list is HTTP 404 → {#collection} returns `[]` (never raises);
  # - a genuinely missing object is HTTP 404 → {#one} raises {Dolibarr::Client::NotFound};
  # - 403 → {Dolibarr::Client::Forbidden} with an actionable message;
  # - anything else → {Dolibarr::Client::Error}, the transport error kept as `#cause`.
  #
  # Domains talk to `connection.call(..., type: nil)` directly rather than the typed
  # sub-client `get`s, because those pin `type: Models::Obj` — a placeholder model that
  # drops the real payload. `type: nil` returns the parsed JSON untouched.
  class Resource
    def initialize(client)
      @client = client
    end

    private

    attr_reader :client

    # The raw transport connection (the "single HTTP choke-point" of dolibarr-api).
    def connection
      client.connection
    end

    # URL-encode a value for interpolation into a request path (id, ref, …).
    def encode(value)
      ERB::Util.url_encode(value.to_s)
    end

    # GET a list endpoint through the raw connection (`type: nil` to keep the parsed
    # JSON), normalising the empty-list 404 to [].
    def get_list(path, **query)
      collection { connection.call(:GET, path, type: nil, auth: ['api_key'], query: query).data }
    end

    # GET a single object through the raw connection; a 404 becomes NotFound.
    def get_one(path, what, **query)
      one(what) { connection.call(:GET, path, type: nil, auth: ['api_key'], query: query).data }
    end

    # Format a date for Dolibarr ("YYYY-MM-DD"); passes strings through untouched.
    def iso_date(value)
      value.respond_to?(:strftime) ? value.strftime('%Y-%m-%d') : value.to_s
    end

    # List semantics: an empty-list 404 is normalised to `[]`.
    def collection
      yield
    rescue Dolibarr::Api::ApiError => e
      return [] if e.status == 404

      raise translate(e)
    end

    # Single-object semantics: a 404 means genuinely not found.
    # @param what [String] noun used in the NotFound message (e.g. "invoice")
    def one(what)
      yield
    rescue Dolibarr::Api::ApiError => e
      raise Client::NotFound, "#{what} not found" if e.status == 404

      raise translate(e)
    end

    # Write/other semantics: no 404 normalisation.
    def call
      yield
    rescue Dolibarr::Api::ApiError => e
      raise translate(e)
    end

    # Maps a transport error onto the gem's error surface. Raised inside a `rescue`
    # by the callers above, so Ruby sets `#cause` to the original transport error.
    def translate(error)
      case error.status
      when 403
        Client::Forbidden.new(
          'permission denied by Dolibarr (403): the API user lacks the rights for this ' \
          'operation — grant them in Dolibarr (Users & Groups → permissions)'
        )
      else
        Client::Error.new(error.message)
      end
    end

    # Transparent pagination. Fetches fixed-size pages (0-based, matching Restler)
    # via the given block until a short or empty page, and returns a lazy Enumerator
    # over the flattened items. The block receives `(page, limit)` and returns that
    # page's array.
    #
    # @param limit [Integer] page size
    # @yieldparam page [Integer] 0-based page index
    # @yieldparam limit [Integer] page size
    # @return [Enumerator]
    def paginate(limit: 100)
      Enumerator.new do |yielder|
        page = 0
        loop do
          batch = yield(page, limit)
          break if batch.nil? || batch.empty?

          batch.each { |item| yielder << item }
          break if batch.size < limit

          page += 1
        end
      end
    end
  end
end
