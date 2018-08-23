component displayname="Jira REST API Manager" output="false" {
	
	/* Jira 5 REST API Docs
	 * https://developer.atlassian.com/display/JIRADEV/JIRA+REST+API+in+JIRA+5.0
	 **/
	 public string function checkedResponse(callResult){
	 	try{
	 		var preResponse = callResult.getPrefix().filecontent;
	 		if(REFind("2\d{2}",callResult.getPrefix().Statuscode)==0){
	 			if(StructKeyExists(callResult.getPrefix(),"responseheader")){
	 				LOCAL.responseheader = serializeJSON(callResult.getPrefix().responseheader);
	 				preResponse = insert(LOCAL.responseheader & "<BR><BR>", preResponse, 0);
	 			}.
	 			if(StructKeyExists(callResult.getPrefix(),"ErrorDetail")){
	 				LOCAL.ErrorDetail = serializeJSON(callResult.getPrefix().ErrorDetail);
	 				preResponse = insert(LOCAL.ErrorDetail&"<BR><BR>", preResponse, 0);
	 			}
	 			if(StructKeyExists(callResult.getPrefix(),"Statuscode")){
					LOCAL.Statuscode = serializeJSON(callResult.getPrefix().Statuscode);
	 				preResponse = insert(LOCAL.Statuscode&"<BR>", preResponse, 0);
	 			}
	 			throw("Error code: #callResult.getPrefix().Statuscode#", "Custom","#preResponse#","1");
	 			}else{
	 				var response = preResponse;
	 			}
	 			}catch(any e){
	 				APPLICATION.custom_error.f_catch_error(e);
	 				return serializeJSON({status:"Error",message:'Something went wrong. Please reload or contact support team!'});
	 			}
	 			return response;
	 		}

	/**
	 * @hint "I am the constructor. Give me the Jira REST API config properties and I'll return myself."
	 * @output false
	 **/
	 public component function init( string BaseURL, string UserName, string Password, string Authorization ) {
	 	variables.BaseURL = arguments.BaseURL;
	 	variables.RestURL = arguments.BaseURL & '/rest/api/2/';
	 	variables.UserName = arguments.UserName;
	 	variables.Password = arguments.Password;
	 	variables.Authorization = arguments.Authorization; //cant upload file without Autorization field -> See add Attachment function
	 	return this;
	 }

	/**
	 * @hint "I will create an issue in Jira via the REST API and return the key." 
	 * @output false
	 **/
	 public struct function createIssue(
	 	required string project,
	 	required string issueType,
	 	required string summary,
	 	required string reporter,
	 	string dueDate,
	 	string description,
	 	string assignee,
	 	string priority,
	 	string originalEstimate,
	 	string remainingEstimate,
	 	array customFields = [],
	 	string companiesToFind,
	 	string country,
	 	string inProject,
	 	string foundCompanies,
	 	string procesType
	 	) {
	 	/* Build Issue packet. */
	 	/* Jira Issue Docs: https://developer.atlassian.com/static/rest/jira/5.0.html#id199290 */
	 	if(isNumeric(summary)){summary=summary&".";}
	 	var packet = {
	 		"fields"= {
	 			"project" = {
	 				"key" = arguments.project
	 				},
	 				"issuetype" = {
	 					"name" = arguments.issueType
	 					},
	 					"summary" = "#arguments.summary#",
	 					"reporter" = {
	 						"name" = arguments.Reporter
	 					}
	 				}
	 			};
	 			if(isDefined("dueDate") AND dueDate NEQ ""){
	 				var duedateValue = {
	 					"duedate"  = DateFormat(arguments.dueDate, "yyyy-MM-dd")
	 				};

	 				StructAppend(packet.fields,duedateValue,"true");
	 			}
	 			if(isDefined("description")){
	 				if(isNumeric(description)){description=description&".";}
	 				var descriptionValue = {
	 					"description"  = "#arguments.description#"
	 				};
	 				StructAppend(packet.fields,descriptionValue,"true");
	 			}
	 			if(isDefined("assignee")){
	 				var assigneeValue = {
	 					"assignee" = {
	 						"name" = arguments.assignee
	 					}
	 				};
	 				StructAppend(packet.fields,assigneeValue,"true");
	 			}
	 			if(isDefined("priority")){
	 				var priorityValue = {
	 					"priority" = {
	 						"name" = arguments.priority
	 					}
	 				};
	 				StructAppend(packet.fields,priorityValue,"true");
	 			}
	 			if(isDefined("originalEstimate")){
	 				var originalEstimateValue = {
	 					"timetracking" = {
	 						"originalEstimate" = arguments.originalEstimate
	 					}
	 				};
	 				StructAppend(packet.fields,originalEstimateValue,"true");
	 			}
	 			if(isDefined("remainingEstimate")){
	 				var remainingEstimateValue = {
	 					"timetracking" = {
	 						"remainingEstimate" = arguments.remainingEstimate
	 					}
	 				};
	 				StructAppend(packet.fields,remainingEstimateValue,"true");
	 			}
	 			if(isDefined("companiesToFind") AND companiesToFind NEQ ""){
	 				var companiesToFindValue = {
	 					"customfield_10100" = arguments.companiesToFind
	 				};
	 				StructAppend(packet.fields,companiesToFindValue,"true");
	 			}
	 			if(isDefined("country") AND country NEQ ""){
	 				var countryValue = {
	 					"customfield_10200" = {
	 						"value" = arguments.country
	 					}
	 				};
	 				StructAppend(packet.fields,countryValue,"true");
	 			}
	 			if(isDefined("inProject") AND inProject NEQ ""){
	 				var inProjectValue = {
	 					"customfield_10201" = {
	 						"value" = arguments.inProject
	 					}
	 				};
	 				StructAppend(packet.fields,inProjectValue,"true");
	 			}
	 			if(isDefined("foundCompanies") AND foundCompanies NEQ ""){
	 				var foundCompaniesValue = {
	 					"customfield_10101" = arguments.foundCompanies
	 				};
	 				StructAppend(packet.fields,foundCompaniesValue,"true");
	 			}
	 			if(isDefined("procesType") AND procesType NEQ ""){
	 				var procesTypeValue = {
	 					"customfield_10202" = {
	 						"value" = arguments.procesType
	 					}
	 				};
	 				StructAppend(packet.fields,procesTypeValue,"true");
	 			}
	 			/* Add Custom Fields */
	 			for (var field in arguments.customFields) {
	 				packet.fields['customfield_' & field.id] = field.value;
	 			}

	 			/* Get http object. */
	 			var httpSvc = getHTTPRequest();
	 			/* Set it up. */
	 			httpSvc.addParam( type="header", name="Content-Type", value="application/json" );
	 			httpSvc.addParam( type="body", value=serializeJSON(packet) );
	 			/* Post to Jira */
	 			var callResult = httpSvc.send( method = "POST", url = variables.RestURL & 'issue' );
	 			return deserializeJSON(checkedResponse(callResult));
	 		}
	 		
	/**
	 * @hint "I will create a comment on an issue in Jira via the REST API and return the ID." 
	 * @output false
	 **/
	 public struct function createIssueComment(
	 	required string IssueKey,
	 	required string Body
	 	) {
	 	/* Build Comment packet. */
	 	/* Jira Comment Docs: https://developer.atlassian.com/static/rest/jira/5.0.html#id199362 */
	 	if(isNumeric(Body)){Body=Body&".";}
	 	var packet = {
	 		"body" = convertHTMLToWiki(arguments.Body)
	 	};

	 	/* Get http object. */
	 	var httpSvc = getHTTPRequest();
	 	/* Set it up. */
	 	httpSvc.addParam( type="header", name="Content-Type", value="application/json" );
	 	httpSvc.addParam( type="body", value=serializeJSON(packet) );
	 	/* Post to Jira */
	 	var callResult = httpSvc.send( method = "POST", url = variables.RestURL & 'issue/' & arguments.IssueKey & '/comment' );
	 	return deserializeJSON(checkedResponse(callResult));
	 }

	 public struct function editIssue(required string IssueKey, string description, string subject, string sharedUsers){
	 	var httpSvc = getHTTPRequest();
	 	var packet = {
	 	};
	 	if(isDefined("subject")){
	 		if(isNumeric(subject)){subject=subject&".";}
	 		var subjectValue = {
	 			"fields"= {
	 				"summary" = "#arguments.subject#"
	 			}
	 		};
	 		StructAppend(packet,subjectValue,"true");
	 	}
	 	if(isDefined("description")){
	 		if(isNumeric(description)){description=description&".";}
	 		var descriptionValue = {
	 			"fields"= {
	 				"description" = "#arguments.description#"
	 			}
	 		};
	 		StructAppend(packet,descriptionValue,"true");
	 	}
	 	if(isDefined("sharedUsers")){
	 		var sharedUsersValue = {
	 			"fields"= {
	 				"customfield_10300" = "#arguments.sharedUsers#"
	 			}
	 		};
	 		StructAppend(packet,sharedUsersValue,"true");
	 	}

	 	httpSvc.addParam( type="header", name="Content-Type", value="application/json" );
	 	httpSvc.addParam( type="body", value=serializeJSON(packet) );
	 	var callResult = httpSvc.send( method = "PUT", url = variables.RestURL & 'issue/' & arguments.IssueKey );
	 	checkedResponse(callResult);
	 	return callResult;
	 }

	 public struct function deleteIssue(required string IssueKey){
	 	var httpSvc = getHTTPRequest();
	 	httpSvc.addParam( type="header", name="Content-Type", value="application/json" );
	 	var callResult = httpSvc.send( method = "DELETE", url = variables.RestURL & 'issue/' & arguments.IssueKey );
	 	checkedResponse(callResult);
	 	return callResult;
	 }

	 public struct function editIssueComment(required string IssueKey,required string CommentKey, string changedDescription){
	 	var httpSvc = getHTTPRequest();
	 	if(isNumeric(changedDescription)){changedDescription=changedDescription&".";}
	 	var packet = {
	 		"body"= arguments.changedDescription
	 	};
	 	httpSvc.addParam( type="header", name="Content-Type", value="application/json" );
	 	httpSvc.addParam( type="body", value=serializeJSON(packet) );

	 	var callResult = httpSvc.send( method = "PUT", url = variables.RestURL & 'issue/' & arguments.IssueKey & '/comment/' & arguments.CommentKey);
	 	checkedResponse(callResult);
	 	return callResult;
	 }

	/**
	* @hint "I transition an issue in Jira"
	* @output false
	**/
	public void function transitionIssue( required string IssueKey, required string TransitionName ) {
		var transitionID = getTransitionIDByName( arguments.IssueKey, arguments.TransitionName );
		if (len(transitionID) == 0) {
			/* no transition is available for the name */
			return;	
		}
		/* Build Transition packet. */
		/* Jira Transition Docs: http://docs.atlassian.com/jira/REST/latest/#id326996 */
		var packet = {
			"transition": {
				"id": transitionID
			}
		};
		/* Get http object. */
		var httpSvc = getHTTPRequest();
		/* Set it up. */
		httpSvc.addParam( type="header", name="Content-Type", value="application/json" );
		httpSvc.addParam( type="body", value=serializeJSON(packet) );
		/* Post to Jira */
		httpSvc.send( method = "POST", url = variables.RestURL & 'issue/' & arguments.IssueKey & '/transitions' );
	}
	
	/**
	* @hint "I get a transition id from a name"
	* @output false
	**/
	public string function getTransitionIDByName( required string IssueKey, required string TransitionName ) {
		var transitionID = "";
		var transitions = getAvailableTransitions( IssueKey );
		for (var transition in transitions) {
			if ( transition.name == arguments.TransitionName ) {
				transitionID = transition.id;
			}	
		}
		return transitionID;
	}
	
	/**
	* @hint "I get all the possible transitions for an issue"
	* @output false
	**/
	public array function getAvailableTransitions( required string IssueKey ) {
		/* Get http object. */
		var httpSvc = getHTTPRequest();
		/* GET from Jira */
		var callResult = httpSvc.send( method = "GET", url = variables.RestURL & 'issue/' & arguments.IssueKey & '/transitions?expand=transitions.fields' );
		deserializeJSON(checkedResponse(callResult));
		return [];
	}

	/**
	 * @hint "I will fetch an issue from Jira via the REST API." 
	 * @output false
	 **/
	 public struct function getIssue( required string Key ) {
	 	/* Get http object. */
	 	var httpSvc = getHTTPRequest();
	 	/* GET from Jira */
	 	var callResult = httpSvc.send( method = "GET", url = variables.RestURL & 'issue/' & arguments.Key );
	 	return deserializeJSON(checkedResponse(callResult));
	 }

	 public string function newComment( string issueKey, string pimLogin, string mylogin ) {
        LOCAL.response = getIssue(issueKey);//2017-08-21T13:05:31.523+0300
	 	/* writeDump(response);abort; */
        LOCAL.newComments=0;

	 	if(isDefined("LOCAL.response.fields.lastViewed")){
            LOCAL.lastViewedTxt = LOCAL.response.fields.lastViewed.toString();
        } else {
            LOCAL.lastViewedTxt = "1995-07-10T07:33:36.110+0300";
        };

		LOCAL.lastViewed = parseDateTime(LOCAL.lastViewedTxt, "yyyy-MM-dd'T'HH:mm:ss.SSSX");

        if(LOCAL.response.fields.comment.maxResults <= LOCAL.response.fields.comment.total){
            LOCAL.lineCount = LOCAL.response.fields.comment.maxResults;
        } else {
            LOCAL.lineCount = LOCAL.response.fields.comment.total;
        };

	 			for(LOCAL.i=1;LOCAL.i<=LOCAL.lineCount;LOCAL.i++){
	 				if(LOCAL.response.fields.comment.comments[#LOCAL.i#].author.key EQ pimLogin){
	 					if(mylogin EQ listfirst(LOCAL.response.fields.comment.comments[#LOCAL.i#].body," ")){
                            LOCAL.lastViewed = parseDateTime(LOCAL.response.fields.comment.comments[#LOCAL.i#].updated, "yyyy-MM-dd'T'HH:mm:ss.SSSX");
	 					}
	 				}
	 			}
	 			for(LOCAL.i=1;LOCAL.i<=LOCAL.lineCount;LOCAL.i++){
                    LOCAL.com = parseDateTime(LOCAL.response.fields.comment.comments[#LOCAL.i#].updated, "yyyy-MM-dd'T'HH:mm:ss.SSSX");
	 				/* lastViewed = dateAdd('m', -5, com);  ///change time of last viewed*/
                    LOCAL.comNew = DateCompare(LOCAL.com, LOCAL.lastViewed);
	 				if(LOCAL.comNew EQ 1){
                        LOCAL.newComments++;
	 				}
	 			};
	 			return LOCAL.newComments;
	 		}


	 		/* UTILITY METHODS */

	/**
	* @hint "I will convert HTML to Jira wiki markup."
	* @output false
	**/
	public string function convertHTMLToWiki( required String markup ) {
		var wiki = arguments.markup;
		wiki = reReplaceNoCase(wiki, "<br[^>]*[/]*>", chr(10), "all");	/* Replace <br>s with a line break. */
		wiki = reReplaceNoCase(wiki, "<"&"p>", chr(10), "all");			/* Replace opening <p>s with a line break. */
		wiki = reReplaceNoCase(wiki, "<"&"/p>", "", "all");				/* Remove closing <p>s. */
		wiki = reReplaceNoCase(wiki, "[\r\n]\s+[\r\n]", RepeatString(chr(10),2), "all");	/* Remove whitespace between line breaks. */
		wiki = reReplaceNoCase(wiki, ">\s+[\r\n]", ">#chr(10)#", "all");			/* Replace whitespace at the end of a line after a closing tag. */
		wiki = reReplaceNoCase(wiki, "[\r\n]{3,}", RepeatString(chr(10),2), "all");	/* Replace 3 or more line breaks with just two. */
		wiki = reReplaceNoCase(wiki, "<[/]*(strong|b)>", "*", "all");				/* Replace <strong|b> with wiki markup. */
		wiki = reReplaceNoCase(wiki, "<[/]*(em|i)>", "_", "all");					/* Replace <em|i> with wiki markup. */
		wiki = reReplaceNoCase(wiki, '<img[^>]+src="(.*?)"[^>]*>', "!\1!", "all");	/* Replace <img> with wiki markup. */
		return wiki;
	}
	
	/**
	* @hint "I will convert Jira wiki markup to HTML."
	* @output false
	**/
	public string function convertWikiToHTML( required String markup ) {
		var html = arguments.markup;
		html = reReplaceNoCase(html, chr(10), "<br />", "all"); /* replace line breaks with a br tag */
		return html;
	}
	
	/**
	 * @hint "I will give you a partially populated http request." 
	 * @output false
	 **/
	 public component function getHTTPRequest() {
	 	var httpSvc = new HTTP( username = variables.UserName, password = variables.Password );
	 	httpSvc.addParam( type="header", name="Accept", value="application/json" );
	 	return httpSvc;
	 }

	 //dont work!!!!!!!!!!!
	 //________________________________________________________________________
	 public string function searchPOST(string ProjectKey){
	 	/* Build Issue packet. */
	 	var packet = {
	 		"jql"= {
	 			"project" = "PIM",
	 			"startAT" = 0
	 			},
	 			"maxResults" = 5
	 		};
	 		var httpSvc = getHTTPRequest();
	 		/* Set it up. */
	 		httpSvc.addParam( type="header", name="Content-Type", value="application/json" );
	 		httpSvc.addParam( type="body", value=serializeJSON(packet) );
	 		/* GET from Jira */
	 		var callResult = httpSvc.send( method = "POST", url = variables.RestURL & 'search');
	 		return deserializeJSON(checkedResponse(callResult));
	 	}
	 	//_____________________________________________________________________________



	 	public struct function searchGET(required string jql, string maxResults = "5", string fields = "all"){
	 		/* Build Issue packet. */
	 		var packet = {
	 			"maxResults" = arguments.maxResults,
	 			"startAt" = 0,
	 			"jql" = arguments.jql
	 		};
	 		/* Get http object. */
	 		var httpSvc = getHTTPRequest();
	 		/* Set it up. */
	 		httpSvc.addParam( type="header", name="Content-Type", value="application/json" );
	 		httpSvc.addParam( type="body", value=serializeJSON(packet) );
	 		/* GET from Jira */
	 		var callResult = httpSvc.send( method = "POST", url = variables.RestURL & 'search');
	 		return deserializeJSON(checkedResponse(callResult));
	 	}

	 	public struct function createMetaGET(string projectIds, string projectKeys, string issuetypeIds, string issuetypeNames, boolean expand){
	 		var httpSvc = getHTTPRequest();
	 		httpSvc.addParam( type="header", name="Content-Type", value="application/json" );
	 		var url = variables.RestURL & 'issue/createmeta?';
	 		if(isDefined('projectIds')){
	 			url = url&"projectIds="&projectIds&"&";
	 		}
	 		if(isDefined('projectKeys')){
	 			url = url&"projectKeys="&projectKeys&"&";
	 		}
	 		if(isDefined('issuetypeIds')){
	 			url = url&"issuetypeIds="&issuetypeIds&"&";
	 		}
	 		if(isDefined('issuetypeNames')){
	 			url = url&"issuetypeNames="&issuetypeNames&"&";
	 		}
	 		if(expand){
	 			url = url&"expand=projects.issuetypes.fields";
	 		}
	 		var callResult = httpSvc.send( method = "GET", url=url);
	 		return deserializeJSON(checkedResponse(callResult));
	 	}

	 	public array function getAllProjects(){
	 		/* Get http object. */
	 		var httpSvc = getHTTPRequest();
	 		httpSvc.addParam( type="header", name="Content-Type", value="application/json" );
	 		var callResult = httpSvc.send( method = "GET", url = variables.RestURL & 'project');
	 		return deserializeJSON(checkedResponse(callResult));
	 	}

	 	/* public array function getAssignableUsers(){
	 		var httpSvc = getHTTPRequest();
	 		httpSvc.addParam( type="header", name="Content-Type", value="application/json" );
	 		var callResult = httpSvc.send( method = "GET", url = variables.RestURL & 'user/assignable/search?project=' & variables.ProjectKey);
	 		return deserializeJSON(checkedResponse(callResult));
	 	} */

	 	public array function getPriorities(){
	 		/* Get http object. */
	 		var httpSvc = getHTTPRequest();
	 		httpSvc.addParam( type="header", name="Content-Type", value="application/json" );
	 		var callResult = httpSvc.send( method = "GET", url = variables.RestURL & 'priority');
	 		return deserializeJSON(checkedResponse(callResult));
	 	}

	 	public struct function getSomething(required String something){
	 		/* Get http object. */
	 		var httpSvc = getHTTPRequest();
	 		httpSvc.addParam( type="header", name="Content-Type", value="application/json" );
	 		var callResult = httpSvc.send( method = "GET", url = variables.RestURL & arguments.something);
	 		return deserializeJSON(checkedResponse(callResult));
	 	}

	 	public struct function getAttachment( string attachID, string filepath, string contentType , string name) {
	 		/* Get http object. */
	 		var httpSvc = getHTTPRequest();
	 		/* GET from Jira */
	 		var callResult = httpSvc.send( method = "GET", url = variables.RestURL & 'attachment/' & arguments.attachID);
	 		//deserializeJSON(checkedResponse(callResult));
	 		var response = deserializeJSON(checkedResponse(callResult));
	 		if(NOT isDefined("arguments.name")){
	 			var callResult = httpSvc.send( method = "GET", url = response[contentType] , getAsBinary="yes", path=filepath);
	 		}
	 		else{
	 			var callResult = httpSvc.send( method = "GET", url = response[contentType] , getAsBinary="yes", path=filepath, file = arguments.name);
	 		}
	 		checkedResponse(callResult);
	 		return callResult;
	 	}

	 	public void function addAttachment( string issueKey, string filepath) {
	 		try{
		 		var oach = 'org.apache.commons.httpclient';
		 		var oachmm = '#oach#.methods.multipart';
		 		var method = createObject('java', '#oach#.methods.PostMethod').init(variables.RestURL & 'issue/' & arguments.issueKey & "/attachments");
		 		var filePart = createObject('java', '#oachmm#.FilePart').init(
		 			'file',
		 			GetFileFromPath(arguments.filePath),
		 			createObject('java', 'java.io.File').init(arguments.filepath)
		 			);

		 		method.setRequestEntity(
		 			createObject('java', '#oachmm#.MultipartRequestEntity').init(
		 				[ filePart ],
		 				method.getParams()
		 				)
		 			);
		 		method.addRequestHeader(
		 			"Authorization", "#variables.Authorization#"
		 			);
		 		method.addRequestHeader(
		 			"x-atlassian-token", "nocheck"
		 			);
		 		status = createObject('java', '#oach#.HttpClient').init().executeMethod(method);
		 		method.releaseConnection();
		 		if(LOCAL.status != 200){
		 			throw("Error code: #LOCAL.status#", "Custom","Add attachment error","1");
		 		}
	 		}catch(any e){
	 			APPLICATION.custom_error.f_catch_error(e);
	 		}
	 		//Using cfhttp method
		/* var httpSvc = getHTTPRequest();
		httpSvc.addParam( type="header", name="cache-control", value="no-cache" );
		httpSvc.addParam( type="header", name="X-Atlassian-Token", value="nocheck" );
		httpSvc.addParam( type="File", name="file", file=filepath, mimetype=fileGetMimeType(filepath));
		//httpSvc.addParam( type="file", name="name", value="ololo", file=filepath);
		 var callResult = httpSvc.send( method = "POST", url = variables.RestURL & 'issue/' & arguments.issueKey & "/attachments");
		 writeOutput(callResult.getPrefix().filecontent);
		 writeDump(callResult);
		 try{
		 var response = deserializeJSON(callResult.getPrefix().filecontent);
		 writeDump(response);
		 	}catch (any e) {
		 		writeOutput(callResult.getPrefix().filecontent);
		 		} */
		 	}


		 }
