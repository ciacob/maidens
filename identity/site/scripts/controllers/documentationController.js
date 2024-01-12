/*
Controller for the `documentation` page.
*/
angular.module("myApp").controller("documentationController", [
  "$scope",
  "dataService",
  function ($scope, dataService) {
    $scope.message = "Welcome to the Documentation page!";
    
  },
]);
