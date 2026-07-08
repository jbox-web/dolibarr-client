# frozen_string_literal: true

module Dolibarr
  class Client
    # Raised when a single object (invoice, thirdparty, …) is requested by id or ref
    # and Dolibarr answers 404. Distinct from an empty list, which is normalised to
    # `[]` and never raises.
    class NotFound < Error
    end
  end
end
