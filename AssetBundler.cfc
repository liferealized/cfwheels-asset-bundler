<cfcomponent output="false">

	<cffunction name="init" access="public" output="false">
		<cfscript>
			StructDelete(application, "assetBundler", false);
			this.version = "1.0,1.1,1.1.1,1.1.2,1.1.3,1.1.4,1.1.5,1.1.6,1.1.7";	
		</cfscript>
		<cfreturn this />
	</cffunction>
	
	<cffunction name="generateBundle" access="public" output="false" returntype="void" mixin="application,controller">
		<cfargument name="type" type="string" required="true" hint="Can be either `js`, `css` or `less`" />
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
				
			arguments.sources = $listClean(arguments.sources);
			
			// create our application scope structs if they do not exist
			if (!StructKeyExists(application, "assetBundler"))
				application.assetBundler = {};
				
			switch (arguments.type)
			{
				case "js":
				{
					loc.relativeFolderPath = application.wheels.webPath & application.wheels.javascriptPath & "/";
					break;
				}
				
				case "less":
				{
					if (application.wheels.showErrorInformation && !StructKeyExists(variables, "generateLessCssFiles"))
						$throw(type="Wheels", message="Plugin Missing", extendedInfo="You must include the less css plugin to bundle less files.");
					
					if (ListFindNoCase("production,testing", application.wheels.environment))
					{
						generateLessCssFiles(sources=arguments.sources);
						arguments.sources = mapLessCssFiles(sources=arguments.sources);
						arguments.type = "css";
						loc.extension = "." & arguments.type;
					}
					break;
				}
			}
			
			if (not StructKeyExists(application.assetBundler, arguments.type))
				application.assetBundler[arguments.type] = {};
			
			// process our sources to see if we have any directories to expand
			loc.array=ListToArray(arguments.sources);
			
			for (i=1; i LTE ArrayLen(loc.array); i=i+1)
			{
				if (REFind("\*$", loc.array[i]))
				{
					// we found a star at the end of the path name so let's get all of 
					// the files under the designated folder for our extension type
					loc.folderFiles = $getAllFilesInDirectory(directoryPath=REReplace(loc.item, "\*$", "", "one"), argumentCollection=loc);
					arguments.sources = ListSetAt(arguments.sources, ListFind(arguments.sources, loc.array[i]), loc.folderFiles);
				}
			}
				
			loc.bundleInfo.name = arguments.bundle;
			loc.bundleInfo.sources = arguments.sources;
				
			// if we are not in testing or production, do nothing
			if (not ListFindNoCase("production,testing", application.wheels.environment))
			{
				application.assetBundler[arguments.type][arguments.bundle] = StructCopy(loc.bundleInfo);
				return;
			}
				
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
			
			if (Find("/", arguments.bundle))
			{
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
		<cfreturn $callOriginalIncludeMethod($includeMethod="styleSheetLinkTag", $fileType="css", argumentCollection=arguments) />
	</cffunction>
	
	
	<cffunction name="javaScriptIncludeTag" access="public" output="false" returntype="string" mixin="controller">
		<cfargument name="sources" type="string" required="false" default="" />
		<cfargument name="type" type="string" required="false" default="#application.wheels.functions.javaScriptIncludeTag.type#" />
		<cfargument name="bundle" type="string" required="false" default="" />
		<cfreturn $callOriginalIncludeMethod($includeMethod="javaScriptIncludeTag", $fileType="js", argumentCollection=arguments) />
	</cffunction>
	
	<cffunction name="$callOriginalIncludeMethod" access="public" output="false" returntype="string" mixin="controller">
		<cfargument name="$includeMethod" type="string" required="true" />
		<cfargument name="$fileType" type="string" required="true" />
		<cfargument name="sources" type="string" required="false" default="" />
		<cfargument name="bundle" type="string" required="true" />
		<cfargument name="type" type="string" required="true" />
		<cfscript>
			var originalIncludeMethod = core[arguments.$includeMethod];
			
			if (not ListFindNoCase("production,testing", application.wheels.environment))
			{
				if (not Len(arguments.sources) and $bundleExists(bundle=arguments.bundle, type=arguments.$fileType))
					arguments.sources = application.assetBundler[arguments.$fileType][arguments.bundle].sources;
				StructDelete(arguments, "bundle");
				return originalIncludeMethod(argumentCollection=arguments);
			}
			
			if (not Len(arguments.bundle) or not $bundleExists(bundle=arguments.bundle, type=arguments.$fileType))
			{
				if (not Len(arguments.sources) and $bundleExists(bundle=arguments.bundle, type=arguments.$fileType))
					arguments.sources = application.assetBundler[arguments.$fileType][arguments.bundle].sources;
				StructDelete(arguments, "bundle");
				return originalIncludeMethod(argumentCollection=arguments);
			}
			
			arguments.sources = arguments.bundle;
			
			StructDelete(arguments, "$includeMethod");
			StructDelete(arguments, "$fileType");
			StructDelete(arguments, "bundle");
			StructDelete(arguments, "source");
		</cfscript>
		<cfreturn originalIncludeMethod(argumentCollection=arguments) />
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
			
			loc.stringReader = createObject("java", "java.io.StringReader").init(arguments.fileContents);
			loc.stringWriter = createObject("java", "java.io.StringWriter").init();
			
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
			var loc = {};
			
			if (!StructKeyExists(server, "javaloader") || !IsStruct(server.javaloader))
				server.javaloader = {};
			
			if (StructKeyExists(server.javaloader, "assetbundler"))
				return server.javaloader.assetbundler;
			
			loc.relativePluginPath = application.wheels.webPath & application.wheels.pluginPath & "/assetbundler/";
			loc.classPath = Replace(Replace(loc.relativePluginPath, "/", ".", "all") & "javaloader", ".", "", "one");
			
			loc.paths = ArrayNew(1);
			loc.paths[1] = ExpandPath(loc.relativePluginPath & "lib/yuicompressor-2.4.7.jar");
			
			// set the javaLoader to the request in case we use it again
			server.javaloader.assetbundler = $createObjectFromRoot(path=loc.classPath, fileName="JavaLoader", method="init", loadPaths=loc.paths, loadColdFusionClassPath=false);
		</cfscript>
		<cfreturn server.javaloader.assetbundler />
	</cffunction>
	
	<cffunction name="$getFileContents" access="public" output="false" returntype="string" mixin="application">
		<cfargument name="fileNames" type="string" required="true" />
		<cfargument name="relativeFolderPath" type="string" required="true" />
		<cfargument name="extension" type="string" required="true" />
		<cfargument name="delimiter" type="string" required="false" default="," />
		<cfscript>
			var loc = { fileContents = "" };
			
			loc.array=ListToArray(arguments.fileNames, arguments.delimiter);
			
			for (i=1; i LTE ArrayLen(loc.array); i=i+1)
			{
				loc.itemRelativePath = arguments.relativeFolderPath & Trim(loc.array[i]);
			
				if (Reverse(arguments.extension) neq Left(Reverse(loc.itemRelativePath), Len(arguments.extension)))
					loc.itemRelativePath = loc.itemRelativePath & arguments.extension;
			
				loc.itemFilePath = ExpandPath(loc.itemRelativePath);
				
				if (!FileExists(loc.itemFilePath))
					$throw(type="Wheels.AssetFileNotFound", message="Could not find the file '#loc.itemRelativePath#'.", extendedInfo="Create a file named '#loc.item##arguments.extension#' in the '#arguments.relativeFolderPath#' directory (create the directory as well if it doesn't already exist).");
				
				// get each of our files and concantenate them together
				loc.file = $file(action="read", file=loc.itemFilePath);
				
				if (arguments.extension == ".css")
					loc.file = $appendQueryStringToUrls(loc.file);
				
				loc.fileContents = loc.fileContents & loc.file;
			}
			
			return loc.fileContents;
		</cfscript>
	</cffunction>	
	<cffunction name="$getAllFilesInDirectory" access="public" output="false" returntype="string" mixin="application">
		<cfargument name="directoryPath" type="string" required="true" />
		<cfargument name="relativeFolderPath" type="string" required="true" />
		<cfargument name="extension" type="string" required="true" />
		<cfargument name="delimiter" type="string" required="false" default="," />
		<cfscript>
			var loc = { fileNames = "" };
			
			loc.itemFolderPath = ExpandPath(arguments.relativeFolderPath & Trim(arguments.directoryPath));
			loc.filesQuery = $directory(action="list", directory=loc.itemFolderPath, type="file", filter="*#arguments.extension#", recurse=true);
			
			for (loc.i = 1; loc.i lte loc.filesQuery.Recordcount; loc.i++)
			{
				loc.relativePath = ListLast(ReplaceNoCase(Replace(loc.filesQuery.directory[loc.i], "\", "/", "all") & "/" & loc.filesQuery.name[loc.i], arguments.relativeFolderPath, "|", "all"), "|");
				loc.fileNames = ListAppend(loc.fileNames, loc.relativePath, arguments.delimiter);
			}
		</cfscript>
		<cfreturn loc.fileNames />
	</cffunction>
	
	<cffunction name="$appendQueryStringToUrls" access="public" output="false" returntype="string" mixin="application">
		<cfargument name="fileContents" type="string" required="false" default="" />
		<cfscript>
			var loc = {};
			loc.used = {};
			loc.matches = REMatchNoCase("url\([^\)]*\)", arguments.fileContents);
			
			for (loc.i = 1; loc.i lte ArrayLen(loc.matches); loc.i++)
			{
				if (!StructKeyExists(loc.used, loc.matches[loc.i]))
				{
					loc.replaceWith = ReplaceList(loc.matches[loc.i], "',""", "");
					loc.replaceWith = REReplace(loc.replaceWith, "\)$", $appendQueryString() & ")", "one");
					arguments.fileContents = ReplaceNoCase(arguments.fileContents, loc.matches[loc.i], loc.replaceWith, "all");
					loc.used[loc.matches[loc.i]] = "";
				}
			}
		</cfscript>
		<cfreturn arguments.fileContents />
	</cffunction>

	<cffunction name="$appendQueryString" returntype="string" access="public" output="false" mixin="application">
		<cfscript>
			var returnValue = "";
			// if assetQueryString is a boolean value, it means we just reloaded, so create a new query string based off of now
			// the only problem with this is if the app doesn't get used a lot and the application is left alone for a period longer than the application scope is allowed to exist
			if (IsBoolean(application.wheels.assetQueryString) and YesNoFormat(application.wheels.assetQueryString) == "no")
				return returnValue;
	
			if (!IsNumeric(application.wheels.assetQueryString) and IsBoolean(application.wheels.assetQueryString))
				application.wheels.assetQueryString = Hash(DateFormat(Now(), "yyyymmdd") & TimeFormat(Now(), "HHmmss"));
			returnValue = returnValue & "?" & application.wheels.assetQueryString;
		</cfscript>
		<cfreturn returnValue />
	</cffunction>
	
</cfcomponent>