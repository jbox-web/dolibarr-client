# frozen_string_literal: true

require 'open3'

module E2E
  # Lifecycle for the disposable dockerized Dolibarr used by the e2e suite:
  # `up` (start + wait for auto-install + seed), `client` (a configured wrapper), and
  # `down` (destroy, volumes included). Everything is throwaway and loopback-only;
  # nothing here ever touches a real instance.
  module Instance
    COMPOSE   = ['docker', 'compose', '-f', 'docker-compose.e2e.yml'].freeze
    PROJECT   = 'dolibarr-client-e2e'
    BASE_URL  = 'http://127.0.0.1:7002/api/index.php'
    # Test-only key, seeded onto the admin user. Not a secret — the instance is disposable.
    API_KEY   = 'e2e-test-key-0123456789'
    SUPPORT   = __dir__
    DB        = 'mariadb -udolibarr -pdolibarr dolibarr'

    module_function

    # Start the stack, wait until Dolibarr has auto-installed, then seed it.
    def up
      run!(*COMPOSE, 'up', '-d')
      wait_healthy('mariadb')
      wait_healthy('dolibarr')
      wait_installed
      seed
    end

    # Destroy the stack and its volumes.
    def down
      run!(*COMPOSE, 'down', '-v')
    end

    # A wrapper client pointed at the disposable instance.
    def client
      Dolibarr::Client.new(base_url: BASE_URL, token: API_KEY)
    end

    # Enable the required modules (native activateModule, see enable_modules.php) and
    # set the admin API key. Both steps are idempotent.
    def seed
      enable_modules
      set_api_key
    end

    # --- internals ---

    def enable_modules
      script = File.read(File.join(SUPPORT, 'enable_modules.php'))
      out, status = Open3.capture2e(*COMPOSE, 'exec', '-u', 'www-data', '-T', 'dolibarr', 'php', stdin_data: script)
      raise "module activation failed:\n#{out}" unless status.success?
    end

    def set_api_key
      exec_db("UPDATE llx_user SET api_key = '#{API_KEY}' WHERE rowid = 1;")
    end

    # Poll the container health until healthy (or give up).
    def wait_healthy(service, timeout: 120)
      container = "#{PROJECT}-#{service}-1"
      deadline = monotonic + timeout
      loop do
        status, = Open3.capture2('docker', 'inspect', '--format', '{{.State.Health.Status}}', container)
        break if status.strip == 'healthy'
        raise "#{service} not healthy after #{timeout}s" if monotonic > deadline

        sleep 3
      end
    end

    # Dolibarr auto-installs asynchronously after the container is healthy; wait for the
    # schema (a few hundred llx_ tables) and the admin user to exist.
    def wait_installed(timeout: 240)
      deadline = monotonic + timeout
      loop do
        tables = query_db('SELECT COUNT(*) FROM information_schema.tables ' \
                          "WHERE table_schema = 'dolibarr' AND table_name LIKE 'llx_%';").to_i
        admin  = query_db('SELECT COUNT(*) FROM llx_user WHERE rowid = 1;').to_i
        break if tables > 300 && admin == 1
        raise "Dolibarr did not finish installing after #{timeout}s" if monotonic > deadline

        sleep 5
      end
    end

    # Run SQL, returning nothing (raises on failure).
    def exec_db(sql)
      out, status = Open3.capture2e(*COMPOSE, 'exec', '-T', 'mariadb', 'sh', '-c', "#{DB} -e \"#{sql}\"")
      raise "SQL failed: #{out}" unless status.success?
    end

    # Run SQL, returning the first scalar (empty string on transient failure, so callers
    # can poll without crashing before the DB is ready).
    def query_db(sql)
      out, status = Open3.capture2(*COMPOSE, 'exec', '-T', 'mariadb', 'sh', '-c', "#{DB} -sN -e \"#{sql}\"")
      status.success? ? out.strip : ''
    end

    def run!(*cmd)
      out, status = Open3.capture2e(*cmd)
      raise "command failed (#{cmd.join(' ')}):\n#{out}" unless status.success?
    end

    def monotonic
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
