
@hashbg_sports.controller 'SessionsCtrl', ['$scope','$http','$modalInstance','Auth','flash', ($scope,$http,$modalInstance,Auth,flash) ->
  $scope.login_user =
    email: null
    password: null
  flash.clean()
  
  $scope.login = ->
    Auth.login($scope.login_user).then((user) ->
      $scope.$parent.login_display = user.email
      flash["success"] = "You have been logged in."
      $scope.reset_users()
      $scope.cancel()
    , (error) ->
      debugger
      flash["error"] = "Log in failed due to: " + error
      $scope.reset_users()
    )
    
  $scope.$on "devise:unauthorized", (event, xhr, deferred) ->
    flash.to('login-form-messages')["error"] = xhr.data.error
  #  if $scope.current_user_id
  #    $scope.loginDialog()
  #  else
    
  $scope.reset_users = ->
    $scope.login_user.email = null
    $scope.login_user.password = null
    
  $scope.cancel = ->
    $modalInstance.dismiss "cancel"
]

