/*
This is the main JavaScript file for this AngularJS application.
It defines the AngularJS module and configures its routes using $routeProvider.
*/

angular.module('myApp', ['ngRoute'])
.config(['$routeProvider', function($routeProvider) {
    $routeProvider
    .when('/home', {
        templateUrl: 'identity/site/views/home.html',
        controller: 'homeController'
    })
    .when('/download', {
        templateUrl: 'identity/site/views/download.html',
        controller: 'downloadController'
    })
    .when('/documentation', {
        templateUrl: 'identity/site/views/documentation.html',
        controller: 'documentationController'
    })
    .otherwise({
        redirectTo: '/home'
    });
}])
.controller('mainController', ['$scope', '$location', function($scope, $location) {
    $scope.isActive = function(route) {
        return route === $location.path();
    };
}]);
