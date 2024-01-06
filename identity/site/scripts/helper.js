class Helpers {
    constructor() {
        this.converter = new showdown.Converter();
    }

    /**
     * Converts a Markdown string to HTML.
     * @param {string} textWithMarkdown - The Markdown string to convert.
     * @returns {string} The converted HTML string.
     */
    resolveMarkDown(textWithMarkdown) {
        return this.converter.makeHtml(textWithMarkdown);
    }
}
