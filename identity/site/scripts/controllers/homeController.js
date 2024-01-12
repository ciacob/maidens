/*
Controller for the `home` page.
*/
angular.module("myApp").controller("homeController", [
  "$scope",
  "dataService",
  function ($scope, dataService) {
    $scope.message = "Welcome to the Home page!";

  },
]);
