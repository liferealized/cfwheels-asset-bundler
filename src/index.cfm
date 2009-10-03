<h1>Asset Bundler (Experimental)</h1>

<p>This plugin will override existing functionality within the Wheels core API.</p>

<h2>Methods Overridden</h2>
<p>Here is a listing of the methods that were overridden.</p>
<ul>
	<li>styleSheetLinkTag
		<ul>
			<li><strong>sources</strong> - a list of stylesheet files that you would like included on the page.</li>
			<li><strong>bundle</strong> - the name of the file you want to bundle the list of stylesheet files to.</li>
			<li><strong>compress</strong> - a boolean value of whether to compress the bundled file. Defaults to false.</li>
			<li><strong>type</strong> - The type of file. Defaults to <code>application.wheels.styleSheetLinkTag.type</code>.</li>
			<li><strong>media</strong> - The media type to apply the CSS to. Defaults to <code>application.wheels.styleSheetLinkTag.media</code></li>
		</ul>
	</li>
	<li>javaScriptIncludeTag</li>
		<ul>
			<li><strong>sources</strong> - a list of stylesheet files that you would like included on the page.</li>
			<li><strong>bundle</strong> - the name of the file you want to bundle the list of javascript files to.</li>
			<li><strong>compress</strong> - a boolean value of whether to compress the bundled file. Defaults to false.</li>
			<li><strong>type</strong> - The type of file. Defaults to <code>application.wheels.javaScriptIncludeTag.type</code>.</li>
		</ul>
</ul>

<h2>How to Use</h2>
<p>Once installed, simply use the functions listed above with the proper parameters. When calling these methods, please make sure to specify argument names to keep 
	conflicts from occurring when not using the plugin. For example, do <code>styleSheetLinkTag(sources="core,layout,theme", bundle="all")</code>. When in the Testing or Production environments, the plugin will bundle your
	assets as specified. If you would like to create multiple bundles, simply call either function multiple times using different bundle names. Please make sure 
	to not repeat bundle names as this will have unintended consequences.</p>
<p>Once a bundle is created it will not be recreated until the parameter "reload" is detected in the url. This gives you
	complete control over when the bundle is rebuilt. This is also done to limit file system access while serving bundles in a production
	environment.</p>
<p>I am also pleased to note that this plugin has no dependency on the internal Coldfusion objects so it can be used in shared hosting enviroments where the setting
	"Disable access to internal ColdFusion Java components" is turned on.</p>

<h2>Road Map</h2>
<p>I would like to add the following features to the plugin to make it to a 1.0 release.</p>
<ul>
	<li>Auto reloading of bundles in the Development and Testing Environments. An application structure is already created to facilitate this.</li>
	<li>Once the above is done, have bundling enabled for the Development environment.</li>
	<li>Performance Optimizations. I want to make sure this plugin is a fast as it can be for production scenarios.</li>
</ul>

<h2>Uninstallation</h2>
<p>To uninstall this plugin simply delete the <tt>/plugins/AssetBundler-0.1.zip</tt> file.</p>

<h2>Credits</h2>
<p>This plugin was created by <a href="http://iamjamesgibson.com">James Gibson</a>.</p>


<p><a href="<cfoutput>#cgi.http_referer#</cfoutput>">&lt;&lt;&lt; Go Back</a></p>