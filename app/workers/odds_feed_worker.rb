require 'debugger'

require 'couchrest'

class OddsFeedWorker
  
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence {
    minutely
  }
  
  def initialize
    @config = YAML.parse_file("config/couchdb.yml").to_ruby[Rails.env]
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
    odds_feed = {}

    feed = JSON.parse(File.read('db/fixtures/OddsFeed.json'))
    # feed.keys => ["Feed: ", "FeedDateTime", "FeedTick", "Generated In"]
    feed["Feed: "].each do |distributor_name, sports|
      distributor_name == "Bet365" && sports.each do |sport_name, country_scopes|
        country_scopes.each do |country_scope, leagues|
          leagues.each do |league_name, matches|
            odds_feed[league_name] = matches
          end
        end
      end
    end
    odds_feed
  end
  
  def load_current_leagues
     db = CouchRest.database!(couch_host("leagues"))
     #db.all_docs["rows"]
     db.all_docs["rows"].map{|doc| doc["id"]}
  end
  
  def build_match_id(match_def)
    match_def[0..2] * "/"
  end
  
  def complex_coefficient(odds)
    r = {}
    odds.each do |odd|
      r[odd[4]] ||= {}
      r[odd[4]][odd[0]] = odd[5]
    end
    r
  end
  
  def simple_coefficient(odds)
    r = {}
    odds.each do |odd|
      r[odd[0]] = odd[4] 
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
    db = CouchRest.database!(couch_host(db_name))
    
    existing_entries = db.all_docs["rows"].map{|e|e["id"]}
    
    to_insert = []
    
    matches.each do |match|
      new_doc = build_odds_doc(match)
      
      db_id = build_match_id(match)
      # TODO use bulk update
      if existing_entries.include? db_id
        existing_doc = db.get(db_id)
        if (diff = existing_doc.to_hash.diff(new_doc).except("_id","_rev")).present?
          if (to_add = diff.except(*existing_doc.keys)).present?
            existing_doc.merge!(to_add)
            db.save_doc existing_doc
          else
            new_doc["_id"] = existing_doc["_id"]
            new_doc["_rev"] = existing_doc["_rev"]
            db.save_doc new_doc
          end
        end
      else
        new_doc["_id"] = db_id
        db.save_doc new_doc 
      end
    end
    
  rescue => e
    debugger
    puts
  end
  
  def build_league_doc(league_name, db_name)
    {"_id" => league_name, "db_name" => db_name}
  end
  
  def perform
    oddsFeed = load_odds_feed
    
    leagues_db = CouchRest.database!(couch_host("leagues"))
    leagues = leagues_db.all_docs["rows"].map{|doc| doc["id"]}
        
    oddsFeed.each do |league_name, matches|
      db_name = league_name.gsub(/[\ \.]/,"_").underscore
      update_matches(db_name, matches)
      unless leagues.include? league_name
        leagues_db.save_doc build_league_doc(league_name, db_name)
      end
    end
  end

end
