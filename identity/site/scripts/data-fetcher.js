/* 
Uses the Github API to fetch data about general project information,
current release availability, etc. 
*/

class GitHubAPI {
  constructor(api) {
      this.api = api;
  }

  getReleasesList() {
      return fetch(this.api)
          .then(response => {
              let result = {
                  'responseRaw': null,
                  'responseParsed': null,
                  'httpStatus': response.status,
                  'errors': [],
                  'hasError': !response.ok
              };
              if (!response.ok) {
                  result.errors.push("HTTP error " + response.status);
              }
              return response.text().then(text => {
                  result.responseRaw = text;
                  try {
                      result.responseParsed = JSON.parse(text);
                  } catch (error) {
                      result.errors.push("JSON parsing error: " + error.message);
                      result.hasError = true;
                  }
                  return result;
              });
          })
          .catch(error => {
              return {
                  'responseRaw': null,
                  'responseParsed': null,
                  'httpStatus': -1,
                  'errors': ["Fetch error: " + error.message],
                  'hasError': true
              };
          });
  }

  getReleaseAssets(assetsUrl) {
      return fetch(assetsUrl)
          .then(response => {
              let result = {
                  'responseRaw': null,
                  'responseParsed': null,
                  'httpStatus': response.status,
                  'errors': [],
                  'hasError': !response.ok
              };
              if (!response.ok) {
                  result.errors.push("HTTP error " + response.status);
              }
              return response.text().then(text => {
                  result.responseRaw = text;
                  try {
                      result.responseParsed = JSON.parse(text);
                  } catch (error) {
                      result.errors.push("JSON parsing error: " + error.message);
                      result.hasError = true;
                  }
                  return result;
              });
          })
          .catch(error => {
              return {
                  'responseRaw': null,
                  'responseParsed': null,
                  'httpStatus': -1,
                  'errors': ["Fetch error: " + error.message],
                  'hasError': true
              };
          });
  }
}



