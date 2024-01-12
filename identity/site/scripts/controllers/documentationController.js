/*
Controller for the `documentation` page.
*/
angular.module("myApp").controller("homeController", [
  "$scope",
  "dataService",
  function ($scope, dataService) {
    $scope.message = "Welcome to the Home page!";
    
    async function fetchData() {
      var result = await dataService.gitHubAPI.getReleasesList();
      console.log(result);
    }
    
    // fetchData();
  },
]);

