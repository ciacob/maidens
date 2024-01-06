/**
 * This class provides methods to interact with the GitHub API.
 * It can fetch a list of releases for a repository and the assets for a specific release.
 */
class GitHubAPI {
    /**
     * Constructs a new instance of the GitHubAPI class.
     * @param {string} api - The API endpoint to fetch the list of releases.
     */
    constructor(api) {
        this.api = api;
    }

    /**
     * Fetches a list of releases for the repository.
     * @returns {Object} An object containing the raw and parsed response, the HTTP status code, any errors that occurred, and a flag indicating whether an error occurred.
     */
    async getReleasesList() {
        try {
            const response = await fetch(this.api);
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
            const text = await response.text();
            result.responseRaw = text;
            try {
                result.responseParsed = JSON.parse(text);
            } catch (error) {
                result.errors.push("JSON parsing error: " + error.message);
                result.hasError = true;
            }
            return result;
        } catch (error) {
            return {
                'responseRaw': null,
                'responseParsed': null,
                'httpStatus': -1,
                'errors': ["Fetch error: " + error.message],
                'hasError': true
            };
        }
    }

    /**
     * Fetches the list of assets for a specific release.
     * @param {string} assetsUrl - The API endpoint to fetch the list of assets.
     * @returns {Object} An object containing the raw and parsed response, the HTTP status code, any errors that occurred, and a flag indicating whether an error occurred.
     */
    async getReleaseAssets(assetsUrl) {
        try {
            const response = await fetch(assetsUrl);
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
            const text = await response.text();
            result.responseRaw = text;
            try {
                result.responseParsed = JSON.parse(text);
            } catch (error) {
                result.errors.push("JSON parsing error: " + error.message);
                result.hasError = true;
            }
            return result;
        } catch (error) {
            return {
                'responseRaw': null,
                'responseParsed': null,
                'httpStatus': -1,
                'errors': ["Fetch error: " + error.message],
                'hasError': true
            };
        }
    }
}