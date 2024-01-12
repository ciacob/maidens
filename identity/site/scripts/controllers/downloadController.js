/*
Controller for the `download` page.
*/
angular.module("myApp").controller("downloadController", [
  "$scope",
  "dataService",
  function ($scope, dataService) {
    $scope.message = "Welcome to the Download page!";

    async function fetchData() {
      var result = await dataService.gitHubAPI.getReleasesList();
      console.log(result);
    }
    
    // fetchData();

  },
]);
