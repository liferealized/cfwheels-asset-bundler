# CFWheels Asset Bundler

The asset bundler is a plugin to easily add bunding and compression for your javascript and stylesheet files. This allows you
to keep a neat and organized javascript or css library and combine and minify the files in your testing and production
environments.

This plugin will override existing functionality within the Wheels core API and add a new method.

## New Methods

-  `generateBundle`
   -  `type** - the type of files your are compressing together - can be `js` or `css`
	 -  `source`/`sources` - the files you would like to be compressed together
	 -  `bundle` - the name of the bundled file - it may contain a folder structure ex. `bundles/core`
	 -  `compress` - whether to have the YUI compressor compress the bundled files, defaults to false

Use the `generateBundle()` method in `/events/onapplicationstart.cfm` to specify the bundles that you want to create when in
testing or production mode. The method should only be used here to ensure that your bundles are created before the application
starts serving requests.

The source/sources argument you specify for this method will be saved by the asset bundler. In your layout file, you will only
need to call `javaScriptIncludeTag()` or `styleSheetLinkTag() with the proper bundle name and the asset bundler will decide
what link or script tags to produce based on your environment settings. An example is below.

```coldfusion
<!--- /events/onApplicationStart.cfm --->

<cfset generateBundle(type="css", bundle="bundles/core", compress=true, sources="screen,liquid,style")>

<!--- layout file - maybe /views/layout.cfm ---->

#styleSheetLinkTag(bundle="bundles/core")#
```

## Configuring Environments
By default, the plugin will attempt to generate and use the bundles in test and production environments. The environments
where the plugin executes can be configured in `events/onapplicationstart.cfm` just before generating the bundles.

```coldfusion
<cfset application.wheels.plugins.assetBundler.environments = "development,test,production">

<cfset generateBundle(...)>
```

When in the `design`, `development`, and `maintenance`, the code about will output `<link>` tags for each source listed. In
the `testing` and `production` environments, the same code will produce one `<link>` tag, pointing to
`/sytlesheets/bundles/core.css` (per the example above).

## Overridden Core Methods

-  `styleSheetLinkTag`
    -  `sources` - a list of stylesheet files that you would like included on the page.
		-  `type` - The type of file. Defaults to `application.wheels.styleSheetLinkTag.type`.
    -  `media` - The media type to apply the CSS to. Defaults to `application.wheels.styleSheetLinkTag.media`
    -  `bundle` - the name of the bundled file to use in `testing` and `production`. If the bundle is specified, you should
       not need to list any sources.
		</ul>
-  `javaScriptIncludeTag`
    - `sources` - a list of stylesheet files that you would like included on the page.
    - `type` - The type of file. Defaults to `application.wheels.javaScriptIncludeTag.type`.
    - `bundle` - the name of the bundled file to use in `testing` and `production`. If the bundle is specified, you should
      not need to list any sources.

## How to Use

Once installed, simply use the functions listed above with the proper parameters. When calling these methods, make sure to
specify argument names to keep conflicts from occurring when not using the plugin. For example, do
`#styleSheetLinkTag(sources="core,layout,theme", bundle="all")#`.

When in the `testing` or `production` environments, the plugin will bundle your assets as specified. The bundling will occur
`onApplicationStart()` or when you add the reload parameter into the URL and reload the application.

If you would like to create multiple bundles, simply call the `generateBundle()` method multiple times using different bundle
names. Please make sure to not repeat bundle names as this will have unintended consequences.

Once a bundle is created it will not be recreated until the parameter `reload` is detected in the URL. This gives you
complete control over when the bundle is rebuilt. This is also done to limit file system access while serving bundles in a
production environment.

## Shared Hosting Environments

I am also pleased to note that this plugin has no dependency on the internal ColdFusion objects, so it can be used in shared
hosting enviroments where the setting "Disable access to internal ColdFusion Java components" is turned on.

## Thanks

A big shout out goes to <a href="http://www.compoundtheory.com/">Mark Mandel</a> who is the creator of [JavaLoader][1], which
is used in this project. Also, a big thank you to the [YUI][2] for creating the awesome [YUI compressor][3]. And last but not
least, a big thanks to the [CFWheels core team][4] for creating such an awesome framework.

## Uninstallation
To uninstall this plugin, simply delete the `/plugins/AssetBundler-X.X.zip` file.

## Credits

This plugin was created by [James Gibson][5].

[1]: http://javaloader.riaforge.org/
[2]: http://developer.yahoo.com/yui/
[3]: http://developer.yahoo.com/yui/compressor/
[4]: http://cfwheels.org/
[5]: http://iamjamesgibson.com/
