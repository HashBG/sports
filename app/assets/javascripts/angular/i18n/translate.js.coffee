@hashbg_sports.config(['$translateProvider', ($translateProvider) ->
  $translateProvider.translations('en_US', {
    decimal:  'decimal',
    uk:      'UK',
    us:     'US',
    en_US:  'English'
    de_DE:  'German'
  });
  
  $translateProvider.translations('de_DE', {
    decimal:  'dezimal',
    uk:      'UK',
    us:     'US',
    en_US:  'Englisch'
    de_DE:  'Deutsch'
  });
  
  $translateProvider.preferredLanguage('en_US')
])