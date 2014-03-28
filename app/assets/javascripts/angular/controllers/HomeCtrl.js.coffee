@hashbg_sports.controller 'HomeCtrl', ['$scope', '$location', '$http', ($scope, $location, $http) ->
  $scope.leagues = []
  $scope.selectedBets = {}

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
    
  $scope.isSpecialKey = (key) ->
    (["_id", "_rev", "Full1X2", "$$hashKey"].indexOf(key) >= 0)
    
  $scope.filterKeys = (match) ->
    keys = []
    for k of match
      if ! $scope.isSpecialKey(k)
        keys.push(k)
    keys  
  
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
  
  $scope.printTicket = (ticket) ->
    r = ""
    r += ticket.betType
    if ticket.modifier?
      r += "/" + ticket.modifier
    r += " to " +  ticket.betResult
    r
  
  $scope.printMatchDate = (match) ->
    match.split("/")[0]

  $scope.printMatch = (match) ->
    d = match.split("/")
    d[1] + " v " + d[2]
  
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
    
]
