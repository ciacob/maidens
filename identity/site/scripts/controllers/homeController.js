/*
Controller for the `home` page.
*/
angular.module("myApp").controller("homeController", [
  "$scope",
  "dataService",
  async function ($scope, dataService) {
    $scope.message = "Welcome to the Home page!";
    // var result = await dataService.gitHubAPI.getReleasesList();
    // console.log(result);
  },
]);
