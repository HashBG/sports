require 'couchrest'

module Hashbg
  module CouchdbBase
    
    def initialize
      init_config
    end
    
    def init_config
      @config ||= YAML.load(ERB.new(File.new(config_path).read).result)[Rails.env]
    end

    def config_path
      "config/couchdb.yml"
    end

    def admin_user
      @config["username"]
    end

    def doc_changed?(old_doc, new_doc, &block)
      if (diff = old_doc.to_hash.diff(new_doc).except("_id","_rev")).present?
      block.call diff
      end
    end

    def update_doc!(db, doc_id, new_doc)
      begin
        old_doc = db.get(doc_id)
        doc_changed?(old_doc, new_doc) do |diff|
          new_doc["_id"] = old_doc["_id"] || doc_id
          new_doc["_rev"] = old_doc["_rev"] if old_doc["_rev"]
          db.save_doc new_doc
          logger.info "updated document #{doc_id}"
        end
      rescue RestClient::ResourceNotFound => nfe
        new_doc["_id"] = doc_id
        db.save_doc new_doc
        logger.info "created document #{doc_id}"
      end
    end

    def ensure_admin_permissions!(db)
      update_doc! db, "_security", admin_permissions
    end

    def ensure_read_only_db!(db)
      ensure_admin_permissions!(db)
      update_doc! db, "_design/security", read_only_permissions
    end

    def couch_host(database = "")
      protocol = @config["protocol"]
      username = @config["username"]
      password = @config["password"]
      if username && password
        auth = "#{username}:#{password}@"
      else
        auth = ""
      end
      host = @config["host"]
      port = @config["port"]
      "#{protocol}://#{auth}#{host}:#{port}/#{database}"
    end

    def admin_permissions
      {"admins" => {
          "names" => [admin_user],
          "roles" => [admin_user]
        }, "readers" => {
          "names" => [],
          "roles" => []
        }}
    end

    def read_only_permissions
      {
        "validate_doc_update" =>
        <<-JAVASCRIPT
        function(new_doc, old_doc, userCtx) {
          if(!userCtx || userCtx.name != "#{admin_user}") {
            throw({forbidden: "Bad user"});
          }
        }
      JAVASCRIPT
      }
    end
  end

end