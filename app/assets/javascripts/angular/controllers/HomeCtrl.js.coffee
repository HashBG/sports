@hashbg_sports.controller 'HomeCtrl', ['$scope', '$location', '$http', ($scope, $location, $http) ->
  $scope.selectedBets = {}
  
  $scope.oddsRepresentations = ["decimal", "us", "uk"]
  $scope.oddsRepresentation = "decimal"
  
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
  
  $scope.hasOdds = (match, betType, betResult, modifier) ->
    if modifier?
      r = match[betType][modifier][betResult]
    else
      r = match[betType][betResult]
    r?
  
  $scope.disableSetBet = (match, betType, betResult, modifier) ->
    if $scope.hasOdds(match, betType, betResult, modifier)
      m = $scope.selectedBets[match["_id"]]
      m? && ! $scope.isBetSelected(match, betType, betResult, modifier)
    else
      true
    
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
    ticket.coefficient[$scope.oddsRepresentation]
  
  normalize = (rational) ->
    # greatest common divisor
    a = Math.abs(rational[0])
    b = Math.abs(rational[1])
    while (b != 0) 
      tmp = a
      a = b
      b = tmp % b
 
    numerator = rational[0] / a
    denominator = rational[1] / a
    
    [numerator, denominator];

  $scope.printTicketCoefficientTotal = () ->
    ticketIds = Object.keys($scope.selectedBets)
    if ticketIds.length == 0
      return ""
    else if ticketIds.length == 1
      return $scope.selectedBets[ticketIds[0]].coefficient[$scope.oddsRepresentation]

    start = ticketIds.shift()
    s = parseFloat($scope.selectedBets[start].coefficient["decimal"])
    for ticketId in ticketIds 
      ticket = $scope.selectedBets[ticketId]
      s = s * parseFloat(ticket.coefficient["decimal"])
    s = Math.round(s * 10000) / 10000
    
    if $scope.oddsRepresentation == "decimal"
      s.toString()
    else
      s = normalize [(s-1)*10000, 10000]
      
      if $scope.oddsRepresentation == "uk"
        s[0].toString() + "/" + s[1].toString()
      else
        rational = s[0] / s[1]
        if rational < 1
          Math.round(-(100.0 / rational)).toString()
        else if rational > 1
          "+" + (Math.round(100 * rational).toString())
        else
          "+100"
  
  $scope.showCoefficient = (match, betType, betResult, modifier) ->
    if modifier?
      r = match[betType][modifier][betResult]
    else
      r = match[betType][betResult]
    
    if r?
      r[$scope.oddsRepresentation]
    else
      "no data"

  $scope.switchOddsRepresentation = (representation) ->
    $scope.oddsRepresentation = representation

]
