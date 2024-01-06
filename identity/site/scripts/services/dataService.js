/*
Abstracts away calls to the GitHub API for varioous data retrieval.
*/
angular.module('myApp').service('dataService', function() {
    this.gitHubAPI = new GitHubAPI('https://api.github.com/repos/ciacob/maidens/releases');
});