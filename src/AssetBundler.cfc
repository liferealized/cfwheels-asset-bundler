<cfcomponent output="false">

	<cffunction name="init" access="public" output="false">
		<cfscript>
			if (StructKeyExists(application, "assetBundler"))
				StructDelete(application, "assetBundler");
			
			this.version = "1.0";	
		</cfscript>
		<cfreturn this />
	</cffunction>
	
	<cffunction name="generateBundle" access="public" returntype="void" mixin="application">
		<cfargument name="type" type="string" required="true" hint="Can be either `js` or `css`" />
		<cfargument name="sources" type="string" required="false" default="" />
		<cfargument name="bundle" type="string" required="false" default="" />
		<cfargument name="compress" type="boolean" required="false" default="false" />
		<cfscript>
		
			// this method is used in /events/onApplicationStart.cfm to create the bundles necessary for the application to run
			// this is done on application start so we don't kill an individuals request performance
			// also allows bundling to work accross a server cluster
		
			var loc = {
				  extension = "." & arguments.type
				, relativeFolderPath = application.wheels.webPath & application.wheels.stylesheetPath & "/"
				, bundleInfo = {}
				, bundleContents = ""
			};
			
			if (StructKeyExists(arguments, "source"))
				arguments.sources = arguments.source;
			
			// create our application scope structs if they do not exist
			if (not StructKeyExists(application, "assetBundler"))
				application.assetBundler = {};
			
			if (not StructKeyExists(application.assetBundler, arguments.type))
				application.assetBundler[arguments.type] = {};
				
			loc.bundleInfo.name = arguments.bundle;
			loc.bundleInfo.sources = arguments.sources;
				
			// if we are not in testing or production, do nothing
			if (not ListFindNoCase("production,testing", application.wheels.environment)) {
			
				application.assetBundler[arguments.type][arguments.bundle] = StructCopy(loc.bundleInfo);
				return;
			}
			
			// make sure we have the right root path
			if (arguments.type eq "js")
				loc.relativeFolderPath = application.wheels.webPath & application.wheels.javascriptPath & "/";
				
			loc.bundleFilePath = ExpandPath(loc.relativeFolderPath & arguments.bundle & loc.extension);
			
			// conbine all of the files listed as one file
			loc.bundleContents = $getFileContents(arguments.sources, loc.relativeFolderPath, loc.extension);
			
			// check to see if we should compress the contents
			if (arguments.compress) 
				loc.bundleContents = $compressContents(loc.bundleContents, arguments.type);
			
			// store info about our bundle in the application scope
			loc.bundleInfo.md5hash = Hash(loc.bundleContents);
			loc.bundleInfo.createdAt = Now();
			
			application.assetBundler[arguments.type][arguments.bundle] = StructCopy(loc.bundleInfo);
			
			if (Find("/", arguments.bundle)) {
				loc.directory = ListDeleteAt(arguments.bundle, ListLen(arguments.bundle, "/"), "/");
				if (not DirectoryExists(ExpandPath(loc.relativeFolderPath & loc.directory & "/")))
					$directory(action="create", directory=ExpandPath(loc.relativeFolderPath & loc.directory & "/"));
			}
			
			$file(action="write", file=loc.bundleFilePath, output=loc.bundleContents, mode="644");
		</cfscript>
		<cfreturn />
	</cffunction>
	
	<cffunction name="styleSheetLinkTag" access="public" output="false" returntype="string" mixin="controller">	
		<cfargument name="sources" type="string" required="false" default="" />
		<cfargument name="type" type="string" required="false" default="#application.wheels.functions.styleSheetLinkTag.type#" />
		<cfargument name="media" type="string" required="false" default="#application.wheels.functions.styleSheetLinkTag.media#" />
		<cfargument name="bundle" type="string" required="false" default="" />
		<cfscript>
			var originalStyleSheetLinkTag = core.styleSheetLinkTag;
			
			if (not ListFindNoCase("production,testing", application.wheels.environment)) {
			
				if (not Len(arguments.sources) and $bundleExists(bundle=arguments.bundle, type="css"))
					arguments.sources = application.assetBundler.css[arguments.bundle].sources;
				
				StructDelete(arguments, "bundle");
				return originalStyleSheetLinkTag(argumentCollection=arguments);
			}
			
			if (not Len(arguments.bundle) or not $bundleExists(bundle=arguments.bundle, type="css")) {
			
				if (not Len(arguments.sources) and $bundleExists(bundle=arguments.bundle, type="css"))
					arguments.sources = application.assetBundler.css[arguments.bundle].sources;
					
				StructDelete(arguments, "bundle");
				return originalStyleSheetLinkTag(argumentCollection=arguments);
			}
			
			arguments.sources = arguments.bundle;
			
			StructDelete(arguments, "bundle");
			StructDelete(arguments, "source");
		</cfscript>
		<cfreturn originalStyleSheetLinkTag(argumentCollection=arguments) />
	</cffunction>
	
	
	<cffunction name="javaScriptIncludeTag" access="public" output="false" returntype="string" mixin="controller">
		<cfargument name="sources" type="string" required="false" default="" />
		<cfargument name="type" type="string" required="false" default="#application.wheels.functions.javaScriptIncludeTag.type#" />
		<cfargument name="bundle" type="string" required="false" default="" />
		<cfscript>
			var originalJavaScriptIncludeTag = core.javaScriptIncludeTag;
			
			if (not ListFindNoCase("production,testing", application.wheels.environment)) {
			
				if (not Len(arguments.sources) and $bundleExists(bundle=arguments.bundle, type="js"))
					arguments.sources = application.assetBundler.js[arguments.bundle].sources;
				
				StructDelete(arguments, "bundle");
				return originalJavaScriptIncludeTag(argumentCollection=arguments);
			}
			
			if (not Len(arguments.bundle) or not $bundleExists(bundle=arguments.bundle, type="js")) {
			
				if (not Len(arguments.sources) and $bundleExists(bundle=arguments.bundle, type="js"))
					arguments.sources = application.assetBundler.js[arguments.bundle].sources;
				
				StructDelete(arguments, "bundle");
				return originalJavaScriptIncludeTag(argumentCollection=arguments);
			}
			
			arguments.sources = arguments.bundle;
			
			StructDelete(arguments, "bundle");
			StructDelete(arguments, "source");
		</cfscript>
		<cfreturn originalJavaScriptIncludeTag(argumentCollection=arguments) />
	</cffunction>
	
	<cffunction name="$bundleExists" output="false" returntype="boolean" access="public" mixin="controller">
		<cfargument name="bundle" required="true" type="string" />
		<cfargument name="type" required="true" type="string" hint="can be `js` or 	`css`" />
		<cfscript>
			var returnValue = false;
			
			if (not StructKeyExists(application, "assetBundler"))
				return returnValue;
				
			if (not StructKeyExists(application.assetBundler, arguments.type))
				return returnValue;
				
			if (not StructKeyExists(application.assetBundler[arguments.type], arguments.bundle))
				return returnValue;
				
			returnValue = true;
		</cfscript>
		<cfreturn returnValue />
	</cffunction>
	
	<cffunction name="$compressContents" access="public" output="false" returntype="string" mixin="application">
		<cfargument name="fileContents" type="string" required="true" />
		<cfargument name="type" type="string" required="true" />
		<cfscript>
			var loc = {};
			
			loc.javaLoader = $createJavaLoader();
			
			loc.stringReader = createObject("java","java.io.StringReader").init(arguments.fileContents);
			loc.stringWriter = createObject("java","java.io.StringWriter").init();
			
			if (LCase(arguments.type) == "css")
			{
				loc.yuiCompressor = loc.javaLoader.create("com.yahoo.platform.yui.compressor.CssCompressor").init(loc.stringReader);
				loc.yuiCompressor.compress(loc.stringWriter, JavaCast("int", -1));
			}
			else if (LCase(arguments.type) == "js")
			{
				loc.errorReporter = loc.javaLoader.create("org.mozilla.javascript.tools.ToolErrorReporter").init(JavaCast("boolean", false));
				loc.yuiCompressor = loc.javaLoader.create("com.yahoo.platform.yui.compressor.JavaScriptCompressor").init(loc.stringReader, loc.errorReporter);
				loc.yuiCompressor.compress(loc.stringWriter, JavaCast("int", -1), JavaCast("boolean", true), JavaCast("boolean", false), JavaCast("boolean", false), JavaCast("boolean", false));
			}
			else
			{
				return arguments.fileContents;
			}
			
			loc.stringReader.close();
			loc.compressedContents = loc.stringWriter.toString();
			loc.stringWriter.close();	
			
			return loc.compressedContents;	
		</cfscript>
	</cffunction>

	<cffunction name="$createJavaLoader" access="public" output="false" returntype="any" mixin="application">
		<cfscript>
			if (StructKeyExists(request, "javaLoader"))
				return request.javaLoader;
			
			loc.relativePluginPath = application.wheels.webPath & application.wheels.pluginPath & "/assetbundler/";
			loc.classPath = Replace(Replace(loc.relativePluginPath, "/", ".", "all") & "javaloader", ".", "", "one");
			
			loc.paths = ArrayNew(1);
			loc.paths[1] = ExpandPath(loc.relativePluginPath & "lib/yuicompressor-2.4.2.jar");
			
			// set the javaLoader to the request in case we use it again
			request.javaLoader = $createObjectFromRoot(path=loc.classPath, fileName="JavaLoader", method="init", loadPaths=loc.paths, loadColdFusionClassPath=false);

			return request.javaLoader;
		</cfscript>
	</cffunction>
	
	<cffunction name="$getFileContents" access="public" output="false" returntype="string" mixin="application">
		<cfargument name="fileNames" type="string" required="true" />
		<cfargument name="relativeFolderPath" type="string" required="true" />
		<cfargument name="extension" type="string" required="true" />
		<cfargument name="delimiter" type="string" required="false" default="," />
		<cfscript>
			var loc = {};
			loc.iEnd = ListLen(arguments.fileNames, arguments.delimiter);
			loc.fileContents = "";
			
			for (loc.i = 1; loc.i <= loc.iEnd; loc.i++)
			{
				// get each of our files and concantenate them together
				loc.item = ListGetAt(arguments.fileNames, loc.i, arguments.delimiter);
				loc.itemRelativePath = arguments.relativeFolderPath & loc.item;
				
				if (Reverse(arguments.extension) neq Left(Reverse(loc.itemRelativePath), Len(arguments.extension)))
					loc.itemRelativePath = loc.itemRelativePath & arguments.extension;
				
				loc.itemFilePath = ExpandPath(loc.itemRelativePath);
				
				if (!FileExists(loc.itemFilePath))
				{
					$throw(type="Wheels.AssetFileNotFound", message="Could not find the file '#loc.itemRelativePath#'.", extendedInfo="Create a file named '#loc.item##arguments.extension#' in the '#arguments.relativeFolderPath#' directory (create the directory as well if it doesn't already exist).");
				}
				
				loc.fileContents = loc.fileContents & $file(action="read", file=loc.itemFilePath);
			}
			
			return loc.fileContents;
		</cfscript>
	</cffunction>
	
</cfcomponent>