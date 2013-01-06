<h1>Asset Bundler</h1>

<p>
    The asset bundler is a plugin to easily add bunding and compression for your javascript and stylesheet files. This allows you to keep a neat
    and organized javascript or css library and combine and minify the files in your testing and production environments.
</p>

<p>This plugin will override existing functionality within the Wheels core API and add a new method.</p>

<h2>New Methods</h2>
<ul>
    <li>generateBundle
        <ul>
            <li><strong>type</strong> - the type of files your are compressing together - can be "js" or "css"</li>
            <li><strong>source/sources</strong> - the files you would like to be compressed together</li>
            <li><strong>bundle</strong> - the name of the bundled file - it may contain a folder structure ex. "bundles/core"</li>
            <li><strong>compress</strong> - whether to have the YUI compressor compress the bundled files, defaults to false</li>
        </ul>
    </li>
</ul>

<p>
    Use the <code>generateBundle()</code> method in /events/onapplicationstart.cfm to specify the bundles that you want to create when in testing or production mode.
    The method should only be used here to ensure that your bundles are created before the application starts serving requests.
<p>
</p>
The source/sources argument you specify for this method will be saved by the asset bundler. In your layout file, you will only need to call <code>javaScriptIncludeTag()</code> or <code>styleSheetLinkTag()</code>
with the proper bundle name and the asset bundler will decide what link or script tags to produce based on your environment settings. An example is below.
</p>

<pre>
... in /events/onApplicationStart.cfm

&lt;cfset generateBundle(type="css", bundle="bundles/core", compress=true, sources="screen,liquid,style") /&gt;

... in your layout file - maybe /views/layout.cfm

#styleSheetLinkTag(bundle="bundles/core")#
</pre>

<h2>Configure environments</h2>
<p>By default the plugin will attempt to generate and use the bundles in test and production ens.
    The environments where the plugin executes can be configured onApplicationStart just before generating the bundles</p>

<pre>
&lt;cfset application.wheels.plugins.assetBundler.environments = "development, test, production" /&gt;

&lt;cfset generateBundle.....
</pre>



<p>
    When in the design, development and maintenance the code about will output <code>&lt;link /&gt;</code> tags for each source listed. In the testing and production evnironments
    the same code will produce one <code>&lt;link /&gt;</code> tag pointing to /sytlesheets/bundles/core.css (per the example above).
</p>

<h2>Overridden Methods</h2>
<ul>
    <li>styleSheetLinkTag
        <ul>
            <li><strong>sources</strong> - a list of stylesheet files that you would like included on the page.</li>
            <li><strong>type</strong> - The type of file. Defaults to <code>application.wheels.styleSheetLinkTag.type</code>.</li>
            <li><strong>media</strong> - The media type to apply the CSS to. Defaults to <code>application.wheels.styleSheetLinkTag.media</code></li>
            <li><strong>bundle</strong> - the name of the bundled file to use in testing and production. If the bundle is specified, you should not need to list any sources.</li>
        </ul>
    </li>
    <li>javaScriptIncludeTag</li>
    <ul>
        <li><strong>sources</strong> - a list of stylesheet files that you would like included on the page.</li>
        <li><strong>type</strong> - The type of file. Defaults to <code>application.wheels.javaScriptIncludeTag.type</code>.</li>
        <li><strong>bundle</strong> - the name of the bundled file to use in testing and production. If the bundle is specified, you should not need to list any sources.</li>
    </ul>
</ul>

<h2>How to Use</h2>

<p>
    Once installed, simply use the functions listed above with the proper parameters. When calling these methods, please make sure to specify argument names to keep
    conflicts from occurring when not using the plugin. For example, do <code>styleSheetLinkTag(sources="core,layout,theme", bundle="all")</code>.
</p>
<p>
    When in the Testing or Production environments, the plugin will bundle your assets as specified. The bundling will occur onApplicationStart() or when you
    add the reload parameter into the URL and reload the application.
</p>
<p>
    If you would like to create multiple bundles, simply call the <code>generateBundle()</code> method multiple times using different bundle names. Please make sure
    to not repeat bundle names as this will have unintended consequences.
</p>
<p>
    Once a bundle is created it will not be recreated until the parameter "reload" is detected in the url. This gives you
    complete control over when the bundle is rebuilt. This is also done to limit file system access while serving bundles in a production
    environment.
</p>

<h2>Shared Hosting Environments</h2>

<p>
    I am also pleased to note that this plugin has no dependency on the internal Coldfusion objects so it can be used in shared hosting enviroments where the setting
    "Disable access to internal ColdFusion Java components" is turned on.
</p>

<h2>Thanks</h2>

<p>
    A big shout out goes to <a href="http://www.compoundtheory.com/">Mark Mandel</a> who is the creator of <a href="http://javaloader.riaforge.org/">JavaLoader</a> which
    is used in this project. Also, a big thank you to the <a href="http://developer.yahoo.com/yui/">YUI</a> for creating the awesome
    <a href="http://developer.yahoo.com/yui/compressor/">YUI compressor</a>. And last but not least, a big thanks to the <a href="http://cfwheels.org/community/core-team">wheels core
    team</a> for creating such an awesome framework.
</p>

<h2>Road Map</h2>
<p>I would like to add the following features to the plugin to make it to a 1.0 release.</p>
<ul>
    <li>Looks like we are feature complete!</li>
</ul>

<h2>Uninstallation</h2>
<p>To uninstall this plugin simply delete the <tt>/plugins/AssetBundler-0.9.zip</tt> file.</p>

<h2>Credits</h2>
<p>This plugin was created by <a href="http://iamjamesgibson.com">James Gibson</a>.</p>


<p><a href="<cfoutput>#cgi.http_referer#</cfoutput>">&lt;&lt;&lt; Go Back</a></p>