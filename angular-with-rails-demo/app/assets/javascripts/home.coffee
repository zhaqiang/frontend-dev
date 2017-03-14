rangularis = angular.module('rangularis', [
  'templates',
  'ngRoute',
  'ngResource',
  'controllers',
  'angular-flash.service',
  'angular-flash.flash-alert-directive'
])

rangularis.config([ '$routeProvider', 'flashProvider'
  ($routeProvider, flashProvider)->

    flashProvider.errorClassnames.push('alert-danger')
    flashProvider.warnClassnames.push('alert-warning')
    flashProvider.infoClassnames.push('alert-info')
    flashProvider.successClassnames.push('alert-success')

    $routeProvider
      .when('/',
        templateUrl: 'index.html'
        controller: 'RecipesController'
      ).when('/recipes/:recipeId',
        templateUrl: 'show.html'
        controller: 'RecipeController'
      ).when('/recipes/new',
        templateUrl: 'form.html'
        controller: 'RecipeController'
      ).when('/recipes/:recipeId/edit',
        templateUrl: 'form.html'
        controller: 'RecipeController'
      )
])

controllers = angular.module('controllers',[])

controllers.controller("RecipesController", [ '$scope', '$routeParams', '$location', '$resource'
  ($scope, $routeParams, $location, $resource)->
    $scope.search = (keywords)->  $location.path("/").search('keywords',keywords)
    Recipe = $resource('/recipes/:recipeId', { recipeId: "@id", format: 'json' })

    if $routeParams.keywords
      Recipe.query(keywords: $routeParams.keywords, (results)-> $scope.recipes = results)
    else
      $scope.recipes = []

    $scope.view = (recipeId)-> $location.path("/recipes/#{recipeId}")

    $scope.newRecipe = -> $location.path("/recipes/new")
    $scope.edit      = (recipeId)-> $location.path("/recipes/#{recipeId}/edit")
])

controllers.controller("RecipeController", [ '$scope', '$routeParams', '$resource', '$location', 'flash',
  ($scope,$routeParams,$resource,$location, flash)->
    Recipe = $resource('/recipes/:recipeId', { recipeId: "@id", format: 'json' },
      {
        'save':   {method:'PUT'},
        'create': {method:'POST'}
      }
    )

    if $routeParams.recipeId
      Recipe.get({recipeId: $routeParams.recipeId},
        ( (recipe)-> $scope.recipe = recipe ),
        ( (httpResponse)->
          $scope.recipe = null
          flash.error   = "There is no recipe with ID #{$routeParams.recipeId}"
        )
      )
    else
      $scope.recipe = {}

    $scope.back   = -> $location.path("/")
    $scope.edit   = -> $location.path("/recipes/#{$scope.recipe.id}/edit")
    $scope.cancel = ->
      if $scope.recipe.id
        $location.path("/recipes/#{$scope.recipe.id}")
      else
        $location.path("/")

    $scope.save = ->
      onError = (_httpResponse)-> flash.error = "Something went wrong"
      if $scope.recipe.id
        $scope.recipe.$save(
          ( ()-> $location.path("/recipes/#{$scope.recipe.id}") ),
          onError)
      else
        Recipe.create($scope.recipe,
          ( (newRecipe)-> $location.path("/recipes/#{newRecipe.id}") ),
          onError
        )

    $scope.delete = ->
      $scope.recipe.$delete()
      $scope.back()
])
