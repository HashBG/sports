@hashbg_sports.config(['$translateProvider', ($translateProvider) ->
  
  $translateProvider.useStaticFilesLoader({
    prefix: '/i18n/lang-',
    suffix: '.json'
  });
  
  $translateProvider.preferredLanguage('en_US')
])
