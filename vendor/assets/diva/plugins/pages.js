export default class PagesPlugin
{
    constructor (core)
    {
        this.core = core;
        this.pageToolsIcon = this.createIcon();
    }
 
    /**
    * Open a new window with the page image.
    *
    **/
   
    documentData = data;
   
    $('body').prepend('<div id="diva-info-pane"><h2>Page Level Metadata</h2><div id="diva-info-content"></div></div>');
 
    handleClick: function(event, settings) {
            // Get the page div and figure out the page's filename
            var pageDiv = $(this).parent().parent();
            var filename = $(pageDiv).attr('data-filename');
 
            // Look up the relevant data and display it in the info pane
            // (Assuming `pageData` holds the HTML that is meant to be displayed)
            var pageData = documentData[filename];
            $('#diva-info-content').html(pageData);
        }
 
    createIcon ()
    {
        /*
        * See img/download.svg for the standalone source code for this.
        * */
 
        const pageToolsIcon = document.createElement('div');
        pageToolsIcon.classList.add('diva-download-icon');
 
       let root = document.createElementNS("http://www.w3.org/2000/svg", "svg");
        root.setAttribute("x", "0px");
        root.setAttribute("y", "0px");
        root.setAttribute("viewBox", "0 0 25 25");
        root.id = `${this.core.settings.selector}download-icon`;
 
        let g = document.createElementNS("http://www.w3.org/2000/svg", "g");
        g.id = `${this.core.settings.selector}download-icon-glyph`;
        g.setAttribute("transform", "matrix(1, 0, 0, 1, -11.5, -11.5)");
        g.setAttribute("class", "diva-pagetool-icon");
 
        let path = document.createElementNS("http://www.w3.org/2000/svg", "path");
        path.setAttribute("d", "M36.25,24c0,6.755-5.495,12.25-12.25,12.25S11.75,30.755,11.75,24S17.245,11.75,24,11.75S36.25,17.245,36.25,24z M33,24c0-4.963-4.037-9-9-9s-9,4.037-9,9s4.037,9,9,9S33,28.963,33,24z M29.823,23.414l-5.647,7.428c-0.118,0.152-0.311,0.117-0.428-0.035L18.1,23.433C17.982,23.28,18.043,23,18.235,23H21v-4.469c0-0.275,0.225-0.5,0.5-0.5h5c0.275,0,0.5,0.225,0.5,0.5V23h2.688C29.879,23,29.941,23.263,29.823,23.414z");
 
        g.appendChild(path);
        root.appendChild(g);
 
        pageToolsIcon.appendChild(root);
 
        return pageToolsIcon;
    }
}
 
PagesPlugin.prototype.pluginName = "download";
PagesPlugin.prototype.isPageTool = true;
 
/**
* Make this plugin available in the global context
* as part of the 'Diva' namespace.
**/
(function (global)
{
    global.Diva.PagesPlugin = PagesPlugin;
})(window);