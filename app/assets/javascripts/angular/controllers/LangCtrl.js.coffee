@hashbg_sports.controller('LangCtrl', ['$scope', '$translate', ($scope, $translate) ->

  $scope.changeLang = (key) ->
    $translate.use(key).then((key) ->
      console.log("changed language to " + key + ".");
    , (key) ->
      console.log("could not change language to "+ key+"!");
    )
    
  $scope.currentLanguage = () ->
    $translate.use()
])