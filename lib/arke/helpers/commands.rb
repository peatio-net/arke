# frozen_string_literal: true

module Arke::Helpers
  module Commands
    def conf
      return @conf if @conf

      if config == "--"
        @conf = YAML.safe_load(STDIN.read)
      else
        @conf = YAML.load_file(config)
      end
    end

    def strategies_configs
      strategies = conf["strategies"]&.is_a?(Array) ? conf["strategies"] : []
      strategies << conf["strategy"] if conf["strategy"]&.is_a?(Hash)

      if dry?
        strategies.map! do |s|
          s["dry"] = dry?
          s["target"]["driver"] = "bitfaker"
          s
        end
      end
      strategies.filter! do |s|
        if s["enabled"] == false
          Arke::Log.warn "Strategy ID:#{s['id']} disabled"
          false
        else
          true
        end
      end
      strategies
    end

    def accounts_configs
      if conf["accounts"]&.is_a?(Array)
        return conf["accounts"].map do |config|
          config.each do |key, value|
            config[key] = Arke::Vault::decrypt(value) if value.to_s.start_with?("vault:")
          end
          config
        end
      else
        []
      end
    end

    def safe_yield(blk, *args)
      account = accounts_configs.select {|a| a["id"] == args.first["account_id"] }.first
      blk.call(*args, account)
    rescue StandardError => e
      Arke::Log.error "#{e}: #{e.backtrace.join("\n")}"
    end

    def each_platform(&blk)
      strategies_configs.each do |c|
        puts "Strategy ID #{c['id']}"
        Array(c["sources"]).each do |ex|
          safe_yield(blk, ex)
        end
        safe_yield(blk, c["target"]) if c["target"]
      end
    end
  end
end
