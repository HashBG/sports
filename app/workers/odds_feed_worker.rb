require 'couchrest'

class OddsFeedWorker
  
  include Sidekiq::Worker
  include Sidetiq::Schedulable
  
  sidekiq_options :queue => :odds_feed

  # as long as we don't download data, no reoccurrence
  #recurrence {
  #  minutely
  #}
  
  def initialize
    @config = YAML.load(ERB.new(File.new(config_path).read).result)[Rails.env]
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
  
  def ensure_leagues_db_permissions!(db)
    update_doc! db, "_security", leagues_db_permissions
  end
  
  def ensure_read_only_db!(db)
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
  
  def load_odds_feed
    logger.info "load and parse feed"
    odds_feed = {}
    leagues_feed = {}

    feed = JSON.parse(File.read('db/fixtures/OddsFeed.json'))
    # feed.keys => ["Feed: ", "FeedDateTime", "FeedTick", "Generated In"]
    feed["Feed: "].each do |distributor_name, sports|
      distributor_name == "Bet365" && sports.each do |sport_name, country_scopes|
        country_scopes.each do |country_scope, leagues|
          leagues.each do |league_name, matches|
            odds_feed[league_name] = matches
            leagues_feed[league_name] = {"country" => country_scope}
          end
        end
      end
    end
    [odds_feed, leagues_feed]
  end

  def build_match_id(match_def)
    match_def[0..2] * "/"
  end
  
  def us_odd(rational)
    if rational < 1
      (-(100.0 / rational)).round.to_s
    elsif rational > 1
      "+" + ((100 * rational).round.to_s)
    else
      "+100"
    end
  end
  
  def uk_odd(odd)
    precision = 1.0
    float = odd.to_f
    nr_decimals = float.to_s.split(".")[1].length
    if nr_decimals < 2
      nr_decimals = 2
    end
    nr_decimals.times { precision /= 10 }
    Rational(float - 1.0).rationalize(precision)
  end
  
  def calculate_odd_represantations(odd)
    r = {}
    r["decimal"] = odd
    rational = uk_odd odd
    r["uk"] = rational.to_s
    r["us"] = us_odd(rational)
    r
  end
  
  def complex_coefficient(odds)
    r = {}
    odds.each do |odd|
      r[odd[4]] ||= {}
      r[odd[4]][odd[0]] = calculate_odd_represantations odd[5]
    end
    r
  end
  
  def simple_coefficient(odds)
    r = {}
    odds.each do |odd|
      r[odd[0]] = calculate_odd_represantations odd[4] 
    end
    r
  end

  def build_odds_doc(match_def)
    r = {}
    match_def[3].each do |bet_type, handycap, odds|
      case bet_type
      when "FullOver/Under", "FullAH", "Full1X2 Handicap"
        r[bet_type] = complex_coefficient(odds)
      when "Full1X2", "FullDoubleChance"
        r[bet_type] = simple_coefficient(odds)
      else
        logger.info("Unknown bet_type: "+ bet_type)
      end
    end
    r
  end
  
  def update_matches(db_name, matches)
    logger.info "updating matches for #{db_name}."
    db = CouchRest.database!(couch_host(db_name))
    ensure_read_only_db!(db)
    
    existing_entries = db.all_docs(endkey: "_")["rows"].map{|e|e["id"]}
    
    # TODO use bulk update
    matches.each do |match|
      new_doc = build_odds_doc(match)
      
      match_id = build_match_id(match)
      if existing_entries.include? match_id
        update_doc!(db, match_id, new_doc)
      else
        new_doc["_id"] = match_id
        db.save_doc new_doc 
      end
    end
  end
  
  def build_league_doc(league_name, db_name)
    {"_id" => league_name, "db_name" => db_name}
  end
  
  def perform
    odds_feed, leagues_feed = load_odds_feed
    
    leagues_db = CouchRest.database!(couch_host("leagues"))
    ensure_leagues_db_permissions!(leagues_db)

    # consider using bulk edit for leagues
    #leagues = leagues_db.all_docs(endkey: "_")["rows"]
        
    odds_feed.each do |league_name, matches|
      db_name = league_name.gsub(/[\ \.]/,"_").underscore
      update_matches(db_name, matches)
      
      league_from_feed = leagues_feed[league_name]
      league_from_feed["db_name"] = db_name

      update_doc!(leagues_db, league_name, league_from_feed)
    end
  end
  
  def leagues_db_permissions
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
