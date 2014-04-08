require 'hashbg/couchdb_base'

class OddsFeedWorker
  
  include Hashbg::CouchdbBase
  
  include Sidekiq::Worker
  include Sidetiq::Schedulable
  
  sidekiq_options :queue => :odds_feed

  recurrence {
    hourly.minute_of_hour(*((0..11).to_a.map{|d|d*5}))
  }
  
  def load_odds_feed
    logger.info "load and parse feed"
    odds_feed = {}
    leagues_feed = {}
    
    feed_tick = Redis.current.get("FeedTick").to_i
    feed = Hashbg::Apis.get_odds_feed(feed_tick)
    Redis.current.set("FeedTick", feed["FeedTick"])
    
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
    db = CouchRest.database!(couch_admin_host(db_name))
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
  
  def perform
    odds_feed, leagues_feed = load_odds_feed
    
    leagues_db = CouchRest.database!(couch_admin_host("leagues"))
    ensure_admin_permissions!(leagues_db)
        
    odds_feed.each do |league_name, matches|
      db_name = league_name.gsub(/[\ \.]/,"_").underscore
      update_matches(db_name, matches)
      
      league_from_feed = leagues_feed[league_name]
      league_from_feed["db_name"] = db_name

      update_doc!(leagues_db, league_name, league_from_feed)
    end
  end
end

