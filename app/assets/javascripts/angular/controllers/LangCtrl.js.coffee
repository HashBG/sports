@hashbg_sports.controller('LangCtrl', ['$scope', '$translate', ($scope, $translate) ->

  $scope.changeLang = (key) ->
    $translate.use(key)
    
  $scope.currentLanguage = () ->
    $translate.use()
])