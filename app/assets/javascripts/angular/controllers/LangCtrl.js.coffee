@hashbg_sports.controller 'LangCtrl', ['$scope', '$translate', 'amMoment', ($scope, $translate, amMoment) ->
  
  $scope.changeLang = (key) ->
    amMoment.changeLanguage(key);
    $translate.use(key)
    
  $scope.currentLanguage = () ->
    $translate.use()
]