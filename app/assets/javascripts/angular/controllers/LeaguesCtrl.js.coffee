@hashbg_sports.controller 'LeaguesCtrl', ['$scope', '$location', '$http', ($scope, $location, $http) ->
  $scope.leagues = []
  $scope.selectedBets = {}
  #$http.get("http://192.168.1.101:5984/leagues/_all_docs?include_docs=true").success((data) ->
  $http.get("http://127.0.0.1:5984/leagues/_all_docs?include_docs=true").success((data) ->
    $scope.leagues = data.rows.map (league) -> league.doc
  ).
  error((data, status, headers, config) ->
    console.log(status)
    console.log(headers)
  )
  
  $scope.moreBetsCount = (match) ->
    i = 0
    otherBets = $scope.filterKeys(match)
    for bet in otherBets
      for k, v of match[bet]
        # k can be modifier or result
        if typeof v == 'string'
          i += 1
          break
        else
          i += 1
    i
    
  $scope.showTickets = () ->
    Object.keys($scope.selectedBets).length > 0
    
  $scope.isBetSelected = (match, betType, betResult, modifier) ->
    m = $scope.selectedBets[match["_id"]]
    m? && m.betType == betType && m.betResult == betResult && m.modifier == modifier
  
  $scope.disableSetBet = (match, betType, betResult, modifier) ->
    m = $scope.selectedBets[match["_id"]]
    m? && ! $scope.isBetSelected(match, betType, betResult, modifier)
    
  $scope.removeBet = (ticketId) ->
    delete $scope.selectedBets[ticketId]
  
  $scope.setBet = (match, betType, betResult, modifier) ->
    if $scope.isBetSelected(match, betType, betResult, modifier)
      $scope.removeBet match["_id"]
    else
      if modifier?
        coefficient = match[betType][modifier][betResult]
      else
        coefficient = match[betType][betResult]
    
      $scope.selectedBets[match["_id"]] = {
        betType: betType, betResult: betResult, 
        modifier: modifier, coefficient: coefficient}
  
  $scope.printMatchDate = (match) ->
    match.split("/")[0]

  $scope.printMatch = (match) ->
    d = match.split("/")
    d[1] + " v " + d[2]
  
  $scope.printTicket = (ticket) ->
    r = ""
    r += ticket.betType
    if ticket.modifier?
      r += "/" + ticket.modifier
    r += " to " +  ticket.betResult
    r
  
  $scope.printCoefficient = (matchKey, ticket) ->
    #match = $scope.matches[matchKey]
    #if ticket.modifier?
    #  match[ticket.betType][ticket.modifier][ticket.betResult]
    #else
    #  match[ticket.betType][ticket.betResult]
    ticket.coefficient
  
  $scope.printTicketCoefficientSum = () ->
    s = 0.0
    for ticketId, ticket of $scope.selectedBets
      s += parseFloat(ticket.coefficient)
    if s == 0.0
      ""
    else
      s.toFixed(2)
    
  $scope.isSpecialKey = (key) ->
    (["_id", "_rev", "Full1X2", "$$hashKey"].indexOf(key) >= 0)
    
  $scope.filterKeys = (match) ->
    keys = []
    for k of match
      if ! $scope.isSpecialKey(k)
        keys.push(k)
    keys
    
  $scope.setDetails = (match) ->
    otherBets = $scope.filterKeys(match)
    $scope.details = {}
    $scope.detailsFor = match["_id"]
    for bet in otherBets
      $scope.details[bet] = match[bet]
  
  $scope.toggleDetails = (matchKey, match) ->
    if matchKey == $scope.detailsFor
      $scope.details = null
      $scope.detailsFor = null
    else
      $scope.setDetails(match)
    
  $scope.lastSeq = null
  $scope.currentDb = null
  
  $scope.pollMatches = (db_name) ->
    if $scope.currentDb != db_name
      return
    params = "feed=longpoll"
    if $scope.lastSeq
      params = params + "&since="+ $scope.lastSeq + "&include_docs=true"

    $http.get("http://127.0.0.1:5984/"+db_name+"/_changes?" + params).success((data) ->
      if $scope.currentDb == db_name
        if $scope.lastSeq
          for result in data.results
            $scope.matches[result.doc["_id"]] = result.doc
            if result.doc["_id"] is $scope.detailsFor
              $scope.setDetails result.doc
        $scope.lastSeq = data.last_seq
        $scope.pollMatches(db_name)
    )
  
  $scope.viewMatches = (db_name) ->
    $scope.currentDb = db_name
    $http.get("http://127.0.0.1:5984/"+db_name+"/_all_docs?include_docs=true").success((data) ->
      
      $scope.matches = {}
      
      data.rows.forEach (result) ->
        $scope.matches[result.doc["_id"]] = result.doc
      
      $scope.pollMatches(db_name)
    )
    
]
