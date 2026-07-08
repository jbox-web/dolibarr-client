# frozen_string_literal: true

module Dolibarr
  class Client
    # The single error surface of the gem. Every failure — configuration,
    # business validation, or a wrapped `dolibarr-api` transport error — is
    # raised as (a subclass of) `Dolibarr::Client::Error`, so callers never have
    # to rescue transport classes directly. When wrapping a transport error, the
    # original is preserved as `#cause`.
    class Error < StandardError
    end
  end
end
