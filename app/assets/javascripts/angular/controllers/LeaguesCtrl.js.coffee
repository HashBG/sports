@hashbg_sports.controller 'LeaguesCtrl', ['$scope', '$filter', ($scope, $filter) ->
  $scope.sortingOrder = sortingOrder;
  $scope.reverse = false;
  $scope.filteredItems = [];
  $scope.groupedItems = [];
  $scope.itemsPerPage = 5;
  $scope.pagedItems = [];
  $scope.currentPage = 0;
  $scope.items = $scope.$parent.leagues
  
  searchMatch = (haystack, needle) ->
    if !needle 
      return true
    return haystack.toLowerCase().indexOf(needle.toLowerCase()) != -1

  $scope.search = () ->
    $scope.filteredItems = $filter('filter')($scope.items, (item) ->
      for attr in item 
        if searchMatch(item[attr], $scope.query)
          return true
        return false

      if ($scope.sortingOrder != '')
        $scope.filteredItems = $filter('orderBy')($scope.filteredItems, $scope.sortingOrder, $scope.reverse);

      $scope.currentPage = 0
      $scope.groupToPages()
  )
    
  $scope.groupToPages = () ->
    $scope.pagedItems = []
        
    for item, i in $scope.filteredItems  #(i = 0; i < $scope.filteredItems.length; i++)
      if i % $scope.itemsPerPage == 0
        $scope.pagedItems[Math.floor(i / $scope.itemsPerPage)] = [ item ]
      else
        $scope.pagedItems[Math.floor(i / $scope.itemsPerPage)].push( item )
    
  $scope.range = (start, end) ->
    ret = []
    if (!end)
      end = start
      start = 0
    for i in [start..end] #(i = start; i < end; i++)
      ret.push(i)
    ret
    
  $scope.prevPage = () ->
    if $scope.currentPage > 0
      $scope.currentPage--
    
  $scope.nextPage = () ->
    if $scope.currentPage < $scope.pagedItems.length - 1
      $scope.currentPage++
    
  $scope.setPage = () ->
    $scope.currentPage = this.n

  $scope.search();

  $scope.sort_by = (newSortingOrder) ->
    if $scope.sortingOrder == newSortingOrder
      $scope.reverse = !$scope.reverse

    $scope.sortingOrder = newSortingOrder

    $('th i').each( () ->
      $(this).removeClass().addClass('icon-sort')
    )

    if $scope.reverse
      $('th.'+new_sorting_order+' i').removeClass().addClass('icon-chevron-up')
    else
      $('th.'+new_sorting_order+' i').removeClass().addClass('icon-chevron-down')
]
