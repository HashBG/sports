require 'hashbg/couchdb_base'

module AssetsHelper
  include Hashbg::CouchdbBase
  
  def coefficient_button(variable, bet_type, bet_result, modifier = nil)
    r = '<button type="button" class="btn btn-default btn-sm" ng-click="'

    r << "setBet(#{variable},'#{bet_type}', '#{bet_result}', #{modifier || 'null'})\""
    r << " ng-disabled=\"disableSetBet(#{variable},'#{bet_type}', '#{bet_result}', #{modifier || 'null'})\""
    
    r << ">{{ showCoefficient(#{variable},'#{bet_type}', '#{bet_result}', #{modifier || 'null'}) }}</button>"
    r
  end
  
  def couchdb_leagues_url
    #@couchdb_config ||= YAML.load(ERB.new(File.new(config_path).read).result)[Rails.env]
    if Rails.env == "production"
      "couchdb/leagues"
    else
      "#{couch_host}leagues/_all_docs?include_docs=true&endkey=%22_%22"
    end
  end
  
  def couchdb_league_base
    #@couchdb_config ||= YAML.load(ERB.new(File.new(config_path).read).result)[Rails.env]
    if Rails.env == "production"
      "couchdb/league/"
    else
      couch_host
    end
  end
  
  def couchdb_league_ext
    #@couchdb_config ||= YAML.load(ERB.new(File.new(config_path).read).result)[Rails.env]
    if Rails.env == "production"
      "/matches"
    else
      "/_all_docs?include_docs=true&endkey=%22_%22"
    end
  end
  
  def couchdb_match_changes
    #@couchdb_config ||= YAML.load(ERB.new(File.new(config_path).read).result)[Rails.env]
    if Rails.env == "production"
      "/changes"
    else
      "/_changes"
    end
  end

  def couchdb_match_changes_since
    #@couchdb_config ||= YAML.load(ERB.new(File.new(config_path).read).result)[Rails.env]
    if Rails.env == "production"
      "/changes_since/"
    else
      "/_changes?feed=longpoll&include_docs=true&since=" 
    end
  end
end
