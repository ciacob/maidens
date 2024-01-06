/*
Controller for the `documentation` page.
*/
angular.module("myApp").controller("documentationController", [
  "$scope",
  "dataService",
  async function ($scope, dataService) {
    $scope.message = "Welcome to the Documentation page!";
    // var result = await dataService.gitHubAPI.getReleasesList();
    // console.log(result);
  },
]);
