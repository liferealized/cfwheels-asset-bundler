<cfcomponent output="false">

	<cffunction name="init" access="public">
		<cfset this.version = "0.9.4">
		<cfreturn this />
	</cffunction>
	
	<cffunction name="styleSheetLinkTag" access="public">	
		<cfargument name="sources" type="string" required="true" />
		<cfargument name="bundle" type="string" required="true" />
		<cfargument name="compress" type="boolean" required="false" default="false" />
		<cfargument name="type" type="string" required="false" default="#application.wheels.styleSheetLinkTag.type#" />
		<cfargument name="media" type="string" required="false" default="#application.wheels.styleSheetLinkTag.media#" />
		<cfscript>
			var loc = {};
			loc.css = ".css";
			loc.reload = false;
			loc.delimiter = ",";
			loc.bundleInfo = {};
			loc.relativeFolderPath = application.wheels.webPath & application.wheels.stylesheetpath & "/";
			
			if (application.wheels.environment != "production" and application.wheels.environment != "testing")
				return core.styleSheetLinkTag(arguments.sources, arguments.sources, arguments.type, arguments.media);
			
			loc.reload = $checkReload();
			
			// setup our variables
			loc.bundleFilePath = ExpandPath(loc.relativeFolderPath & arguments.bundle & loc.css); 
			
			if (loc.reload == false and FileExists(loc.bundleFilepath))
				return core.styleSheetLinkTag(arguments.bundle, arguments.bundle, arguments.type, arguments.media);
				
			// if we have made it this far, create the bundled file
			loc.bundleContents = $getFileContents(arguments.sources, loc.relativeFolderPath, loc.css, loc.delimiter);
			
			// add it to the application scope with proper values
			if (not StructKeyExists(application, "assetBundler")) {
				application.assetBundler = {};
			}
			
			if (not StructKeyExists(application.assetBundler, "cssBundles")) {
				application.assetBundler.cssBundles = {};
			}
			
			loc.bundleInfo.md5hash = Hash(loc.bundleContents);
			loc.bundleInfo.name = arguments.bundle;
			loc.bundleInfo.createdAt = Now();
			
			application.assetBundler.cssBundles[arguments.bundle] = StructCopy(loc.bundleInfo);
			
			// check to see if we should compress the contents
			if (compress) 
				loc.bundleContents = $compressContents(loc.bundleContents, "css");
			
			$writeFile(loc.bundleFilePath, loc.bundleContents);
			
			// return an styleSheetLinkTag to the bundle
			return core.styleSheetLinkTag(arguments.bundle, arguments.bundle, arguments.type, arguments.media);
		</cfscript>
	</cffunction>
	
	
	<cffunction name="javaScriptIncludeTag" access="public">
		<cfargument name="sources" type="string" required="true" />
		<cfargument name="bundle" type="string" required="true" />
		<cfargument name="compress" type="boolean" required="false" default="false" />
		<cfargument name="type" type="string" required="false" default="#application.wheels.javaScriptIncludeTag.type#" />
		<cfscript>
			var loc = {};
			loc.js = ".js";
			loc.reload = false;
			loc.delimiter = ",";
			loc.bundleInfo = {};
			loc.relativeFolderPath = application.wheels.webPath & application.wheels.javaScriptPath & "/";
			
			if (application.wheels.environment != "production" and application.wheels.environment != "testing") {
				return core.javaScriptIncludeTag(arguments.sources, arguments.sources, arguments.type);
			}
			
			loc.reload = $checkReload();
			
			// setup our variables
			loc.bundleFilePath = ExpandPath(loc.relativeFolderPath & arguments.bundle & loc.js); 
			
			if (loc.reload == false and FileExists(loc.bundleFilepath))
				return core.javaScriptIncludeTag(arguments.bundle, arguments.bundle, arguments.type);
				
			// if we have made it this far, create the bundled file
			loc.iEnd = ListLen(arguments.sources, loc.delimiter);
			
			loc.bundleContents = $getFileContents(arguments.sources, loc.relativeFolderPath, loc.js, loc.delimiter);
			
			// add it to the application scope with proper values
			if (not StructKeyExists(application, "assetBundler")) {
				application.assetBundler = {};
			}
			
			if (not StructKeyExists(application.assetBundler, "jsBundles")) {
				application.assetBundler.jsBundles = {};
			}
			
			loc.bundleInfo.md5hash = Hash(loc.bundleContents);
			loc.bundleInfo.name = arguments.bundle;
			loc.bundleInfo.createdAt = Now();
			
			application.assetBundler.jsBundles[arguments.bundle] = StructCopy(loc.bundleInfo);
			
			if (compress) 
				loc.bundleContents = $compressContents(loc.bundleContents, "js");
			
			$writeFile(loc.bundleFilePath, loc.bundleContents);
			
			// return an styleSheetLinkTag to the bundle
			return core.javaScriptIncludeTag(arguments.bundle, arguments.bundle, arguments.type);
		
		</cfscript>
	</cffunction>
	
	<cffunction name="$checkReload">
		<cfscript>
			var loc = {};
			loc.reload = false;
		
			if (StructKeyExists(params, "reload")) {
				loc.reload = true;
				
				if (not StructKeyExists(request, "reload")) {
					request.reload = true;
				}
							
				if (request.reload) {
					application.assetBundler = {};
					request.reload = false;
				}
			}
			
			return loc.reload;
		</cfscript>
	</cffunction>
	
	<cffunction name="$compressContents">
		<cfargument name="fileContents" type="string" required="true" />
		<cfargument name="fileType" type="string" required="true" />
		<cfscript>
			var loc = {};
			
			loc.javaLoader = $createJavaLoader();
			
			loc.stringReader = createObject("java","java.io.StringReader").init(arguments.fileContents);
			loc.stringWriter = createObject("java","java.io.StringWriter").init();
			
			if (LCase(arguments.fileType) == "css")
			{
				loc.yuiCompressor = loc.javaLoader.create("com.yahoo.platform.yui.compressor.CssCompressor").init(loc.stringReader);
				loc.yuiCompressor.compress(loc.stringWriter, JavaCast("int", -1));
			}
			else if (LCase(arguments.fileType) == "js")
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

	<cffunction name="$createJavaLoader">
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
	
	<cffunction name="$getFileContents">
		<cfargument name="fileNames" type="string" required="true" />
		<cfargument name="relativeFolderPath" type="string" required="true" />
		<cfargument name="fileExtension" type="string" required="true" />
		<cfargument name="delimiter" type="string" required="true" />
		<cfscript>
			var loc = {};
			loc.iEnd = ListLen(arguments.fileNames, arguments.delimiter);
			loc.fileContents = "";
			
			for (loc.i = 1; loc.i <= loc.iEnd; loc.i++)
			{
				// get each of our files and concantenate them together
				loc.item = ListGetAt(arguments.fileNames, loc.i, arguments.delimiter);
				loc.itemRelativePath = arguments.relativeFolderPath & loc.item & arguments.fileExtension;
				loc.itemFilePath = ExpandPath(loc.itemRelativePath);
				
				if (!FileExists(loc.itemFilePath))
				{
					$throw(type="Wheels.StyleSheetNotFound", message="Could not find the file '#loc.itemRelativePath#'.", extendedInfo="Create a file named '#loc.item##arguments.fileExtension#' in the '#arguments.relativeFolderPath#' directory (create the directory as well if it doesn't already exist).");
				}
				
				loc.fileContents = loc.fileContents & $readFile(loc.itemFilePath);
			}
			
			return loc.fileContents;
		</cfscript>
	</cffunction>
	
	<cffunction name="$readFile">
		<cfargument name="absolutePath" type="string" required="true" />
		<cfset var loc = {} />
		<cffile action="read" file="#arguments.absolutePath#" variable="loc.returnValue" />
		<cfreturn loc.returnValue />
	</cffunction>
	
	<cffunction name="$writeFile">
		<cfargument name="absolutePath" type="string" required="true" />
		<cfargument name="fileContents" type="string" required="true" />
		<cfset var loc = {} />
		<cffile action="write" file="#absolutePath#" output="#arguments.fileContents#" mode="644" />
	</cffunction>
	
</cfcomponent>