@hashbg_sports.controller 'BetCtrl', ['$scope', '$modalInstance', 'selectedBets', '$controller', '$http', '$timeout',($scope, $modalInstance, selectedBets, $controller, $http, $timeout) ->
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
    
    $http.defaults.headers.post['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content');
    $http.post("bet_with_btc", {bets: $scope.selectedBets}).success((data) ->
      $scope.currentProgress = 99
      $scope.btcMin = data.min
      $scope.btcMax = data.max
      $scope.exchangeCourse = data.exchangeCourse
      $scope.btc_address = data.btc_address
      new QRCode(document.getElementById("qrcode"), data.btc_address);
      $scope.startTimer()
      $scope.currentProgress = 100
    )
  
  $scope.finalizeBet = (bet_amount) ->
    $modalInstance.close ""
  
  $scope.cancel = ->
    $modalInstance.dismiss "cancel"
  
  $scope.countdownMax = 300000
  $scope.countdown = $scope.countdownMax 
  
  $scope.countdownPercent = () ->
    ($scope.countdown / $scope.countdownMax) * 100
    
  $scope.onTicker = () ->
    if $scope.countdown > 0
      $scope.countdown = $scope.countdownMax - (Date.now() - $scope.counterStart)
      if $scope.countdown <= 0
        $scope.countdown = 0
      else
        $timeout($scope.onTicker,1000);
      
  $scope.timerElapsed = () ->
    $scope.countdown <= 0
    
  $scope.startTimer = () ->
    $scope.counterStart = Date.now()
    $scope.countdown = $scope.countdownMax
    $timeout($scope.onTicker,1000);
]