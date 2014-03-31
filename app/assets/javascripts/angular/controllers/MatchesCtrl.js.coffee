@hashbg_sports.controller 'MatchesCtrl', ['$scope', '$location', '$http', '$routeParams', '$q', '$rootScope', '$timeout', ($scope, $location, $http, $routeParams, $q, $rootScope, $timeout) ->
  $scope.currentDb = $routeParams.league_name
  $scope.lastSeq = null
  $scope.currentDb = null
  
  if $scope.$parent.canceler
    canceler = $scope.$parent.canceler
    $timeout(() ->
      canceler.resolve("League to follow changed")
    )
  
  $scope.currentLeague = () ->
    $routeParams.league_name
  
  $http.get("http://127.0.0.1:5984/"+$scope.currentLeague()+"/_all_docs?include_docs=true").success((data) ->
    $scope.matches = {}
    
    data.rows.forEach (result) ->
      $scope.matches[result.doc["_id"]] = result.doc
      $scope.matches[result.doc["_id"]]["currentCoefficient"] = result.doc.coefficient 
    
    $scope.pollMatches($scope.currentLeague())
  )
     
  $scope.setDetails = (match) ->
    otherBets = $scope.$parent.filterKeys(match)
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
  
  $scope.pollMatches = (db_name) ->
    if $scope.currentLeague() == null || $scope.currentLeague() != db_name
      return
    params = "feed=longpoll"
    if $scope.lastSeq
      params = params + "&since="+ $scope.lastSeq + "&include_docs=true"
  
    $scope.$parent.canceler = $q.defer();

    $http.get("http://127.0.0.1:5984/"+db_name+"/_changes?" + params, timeout: $scope.$parent.canceler.promise).success((data) ->
      if $scope.currentLeague() == db_name
        if $scope.lastSeq
          for result in data.results
            $scope.matches[result.doc["_id"]] = result.doc
            if result.doc["_id"] is $scope.detailsFor
              $scope.setDetails result.doc
        $scope.lastSeq = data.last_seq
        $scope.pollMatches(db_name)
    ).
    error((err) ->
      # check if aborted
    )
]
