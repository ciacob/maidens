/*
Controller for the `download` page.
*/
angular.module("myApp").controller("downloadController", [
  "$scope",
  "dataService",
  async function ($scope, dataService) {
    $scope.message = "Welcome to the Download page!";
    // var result = await dataService.gitHubAPI.getReleasesList();
    // console.log(result);
  },
]);
