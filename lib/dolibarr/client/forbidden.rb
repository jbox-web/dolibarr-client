# frozen_string_literal: true

module Dolibarr
  class Client
    # Raised when Dolibarr answers 403: the API user is authenticated but lacks the
    # rights for the operation. Carries an actionable message.
    class Forbidden < Error
    end
  end
end
