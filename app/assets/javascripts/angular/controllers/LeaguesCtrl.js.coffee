@hashbg_sports.controller 'LeaguesCtrl', ['$scope', '$location', '$http', ($scope, $location, $http) ->
  
  $scope.leagues = []
  $scope.leaguesMap = {}
  $http.get("http://127.0.0.1:5984/leagues/_all_docs?include_docs=true&endkey=%22_%22").success((data) ->
    for league in data.rows
      $scope.leaguesMap[league.doc.country] or= []
      $scope.leaguesMap[league.doc.country].push league.doc
  ).
  error((data, status, headers, config) ->
    console.log(status)
    console.log(headers)
  )
  
  $scope.expand = (country) ->
    if $scope.expanded == country
      $scope.expanded = null
    else
      $scope.expanded = country

]
