@hashbg_sports.controller 'BetCtrl', ($scope, $modalInstance, selectedBets, $controller, $http, $timeout) ->
  $controller('HomeCtrl', {$scope: $scope});
  $scope.selectedBets = selectedBets
  $scope.exchangeCourse = 0

  $scope.betWithBTC = ->
    $scope.currentProgress = 1
    # as we cannot check what the server does it's nice to show clients that something is happening
    $timeout(() ->
      if $scope.currentProgress < 20
        $scope.currentProgress = 20
    , 10)
    
    $http.get("bet_with_btc").success((data) ->
      $scope.currentProgress = 99
      $scope.btcMin = data.min
      $scope.btcMax = data.max
      $scope.exchangeCourse = data.exchangeCourse
      new QRCode(document.getElementById("qrcode"), data.btc_address);
      $scope.currentProgress = 100
    )
  
  $scope.finalizeBet = (bet_amount) ->
    $modalInstance.close ""
  
  $scope.cancel = ->
    $modalInstance.dismiss "cancel"