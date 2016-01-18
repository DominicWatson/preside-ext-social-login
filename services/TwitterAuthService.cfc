component output=false singleton=true extends="SocialAuthService" {

// CONSTRUCTOR
	/**
	 * @sessionStorage.inject             coldbox:plugin:sessionStorage
	 * @systemConfigurationService.inject systemConfigurationService
	 * @logger.inject                     logbox:logger:TwitterAuthService
	 * @socialAccountDao.inject           presidecms:object:social_account
     * @websiteLoginService.inject        websiteLoginService
     * @userDao.inject                    presidecms:object:website_user
	 */

	public any function init( required any systemConfigurationService, required any logger, required any sessionStorage, required any socialAccountDao, required any websiteLoginService, required any userDao ) output=false {
		 super.init(argumentCollection=arguments)
		return this;
	}

   
	//twitter functions 
    //originally getTwitterRequestToken
    public function initiateTwitterLogin( required string redirectURI) output=false{
        // Variables 
        var config = _getSystemConfigurationService().getCategorySettings( "social-login" );
        var gmt_time_zone = "8"; // Greenwich mean time offset at server 
        var http_method = "POST";
        var request_url = "https://api.twitter.com/oauth/request_token";
        var oauth_consumer_secret = config.twitter_consumer_secret;
        var params = {};
        params["oauth_callback"] = arguments.redirectURI;
        params["oauth_consumer_key"] = config.twitter_consumer_key;
        params["oauth_nonce"] = DateFormat(Now(),'yymmdd') & TimeFormat (Now(),'hhmmssl');
        params["oauth_signature_method"] = "HMAC-SHA1";
        params["oauth_timestamp"] = DateDiff("s", "January 1 1970 00:00", (Now()+(gmt_time_zone/24)));
        params["oauth_version"] = "1.0";
        // Submit OAuth request 
        var oauth_response = _oauthRequest(oauth_consumer_secret,"",http_method,request_url,params);
        // Parse and store the results 
        // Request Token (variable-length) 
        oauth_token_start = Find("oauth_token=",oauth_response)+12;
        oauth_token_end = Find("&",oauth_response,oauth_token_start);
        
        var twitterSession = _getSessionStorage().getVar( name=_getSessionKey(), default={} );

        var twitterSession.oauth_request_token = Mid(oauth_response,oauth_token_start,(oauth_token_end-oauth_token_start));
        // Request Token secret (variable-length)                       
        oauth_token_secret_start = Find("oauth_token_secret=",oauth_response)+19;
        oauth_token_secret_end = Find("&",oauth_response,oauth_token_secret_start);
        twitterSession.oauth_request_token_secret = Mid(oauth_response,oauth_token_secret_start,(oauth_token_secret_end-oauth_token_secret_start));
        //save twitterSession into session
        _getSessionStorage().setVar( name=_getSessionKey(), value=twitterSession );
        // Callback confirmation flag (true/false) 
        // ignored 
        // Forward user to Twitter for authentication 
        location url="https://api.twitter.com/oauth/authorize?oauth_token=#twitterSession.oauth_request_token#";
    }

    public function authoriseTwitterLogin(
              required string oauth_token
            , required string oauth_verifier
        ){
        var config = _getSystemConfigurationService().getCategorySettings( "social-login" );
        var twitterSession = _getSessionStorage().getVar( name=_getSessionKey(), default={} );


        var getAccessToken = getTwitterAccessToken(oauth_token=arguments.oauth_token, oauth_verifier=arguments.oauth_verifier);
        // Get the basics user details so that we have a screen_name we can use
        var getTwitterDetails = getTwitterDetails();
        var twitterData = DeserializeJSON(getTwitterDetails);
        twitterSession.twitter_screen_name = twitterData.screen_name;
        // Build the twitter4j stuff
        var configBuilder = createObject("java", "twitter4j.conf.ConfigurationBuilder");
        configBuilder.setOAuthConsumerKey(config.twitter_consumer_key);
        configBuilder.setOAuthConsumerSecret(config.twitter_consumer_secret);
        configBuilder.setOAuthAccessToken(twitterSession.twitter_access_token);
        configBuilder.setOAuthAccessTokenSecret(twitterSession.twitter_access_token_secret);
        var twitterConfig = configBuilder.build();
        twitterFactory = createObject("java", "twitter4j.TwitterFactory").init(twitterConfig);
        twitter = twitterFactory.getInstance();
        // Now we can get the User ID, Real Name, User Image etc...
        twitterUserDetails = twitter.showUser(twitterSession.twitter_screen_name);
        
        _getSessionStorage().setVar( name=_getSessionKey(), value=twitterSession );
        
        var socialUser = {
          social_id   = twitterUserDetails.getID()
        , label       = twitterUserDetails.getScreenName()
        , firstname   = twitterUserDetails.getName()
        , lastname    = ""
        , email       = ""
        , social_link = "https://twitter.com/" & twitterUserDetails.getScreenName()
        , image_link  = twitterUserDetails.getBiggerProfileImageURL()
        , gender      = ""
        , type        = "twitter"
    }

    
    return _createSocialAccount(socialUser);      
    }

    public function getTwitterAccessToken(
    		  required string oauth_token
    		, required string oauth_verifier
    	) output=false{
        // Variables 
        var config = _getSystemConfigurationService().getCategorySettings( "social-login" );
        var twitterSession = _getSessionStorage().getVar( name=_getSessionKey(), default={} );

        var gmt_time_zone = "8";// Greenwich mean time offset at server 
        var http_method = "POST";
        var request_url = "https://api.twitter.com/oauth/access_token";
        var oauth_consumer_secret = config.twitter_consumer_secret;
         params = {};
         params["oauth_consumer_key"] = config.twitter_consumer_key;
         params["oauth_nonce"] = DateFormat(Now(),'yymmdd') & TimeFormat (Now(),'hhmmssl');
         params["oauth_signature_method"] = "HMAC-SHA1";
         params["oauth_timestamp"] = DateDiff("s", "January 1 1970 00:00", (Now()+(gmt_time_zone/24)));
         params["oauth_token"] = arguments.oauth_token;
         params["oauth_verifier"] = arguments.oauth_verifier;
         params["oauth_version"] = "1.0";
        // Submit OAuth request 
        var oauth_response = _oauthRequest(oauth_consumer_secret,twitterSession.oauth_request_token_secret?:"",http_method,request_url,params);
        // Get token (variable-length) 
        var oauth_token_start = Find("oauth_token=",oauth_response)+12;
        var oauth_token_end = Find("&",oauth_response,oauth_token_start);
        var oauth_access_token = Mid(oauth_response,oauth_token_start,(oauth_token_end-oauth_token_start));
        // Get token secret (variable-length) 
         oauth_token_secret_start = Find("oauth_token_secret=",oauth_response)+19;
         oauth_token_secret_end = Find("&",oauth_response,oauth_token_secret_start);
         var oauth_access_token_secret = Mid(oauth_response,oauth_token_secret_start,(oauth_token_secret_end-oauth_token_secret_start));
        // Set up the SESSION vars 

        twitterSession.twitter_access_token = oauth_access_token;
        twitterSession.twitter_access_token_secret = oauth_access_token_secret;

        _getSessionStorage().setVar( name=_getSessionKey(), value=twitterSession );
        
    }

    //GET BASICS TWITTER ACCOUNT SETTINGS FOR THIS USER
    public function getTwitterDetails(){
        var config = _getSystemConfigurationService().getCategorySettings( "social-login" );
        var twitterSession = _getSessionStorage().getVar( name=_getSessionKey(), default={} );

        var gmt_time_zone = "8"; // Greenwich mean time offset at server 
        var http_method = "POST";
        var request_url = "https://api.twitter.com/1.1/account/settings.json";
        var oauth_consumer_secret = config.twitter_consumer_secret;
        params = {};
        params["oauth_consumer_key"] = config.twitter_consumer_key;
        params["oauth_nonce"] = DateFormat(Now(),'yymmdd') & TimeFormat (Now(),'hhmmssl');
        params["oauth_signature_method"] = "HMAC-SHA1";
        params["oauth_token"] = twitterSession.twitter_access_token;
        params["oauth_timestamp"] = DateDiff("s", "January 1 1970 00:00", (Now()+(gmt_time_zone/24)));
        params["oauth_version"] = "1.0";
        // Submit OAuth request 
        var oauth_response = _OauthRequest(oauth_consumer_secret,twitterSession.twitter_access_token_secret,http_method,request_url,params);
        // Display the results 
        return oauth_response;
    }



    //RFC 3986-compliant Urlencodedformat() Function      
    private string function _URLEncodedFormat3986(
    	required string str
    ){
        var rfc_3986_bad_chars = "%2D,%2E,%5F,%7E";
        var rfc_3986_good_chars = "-,.,_,~";
        arguments.str = ReplaceList(URLEncodedFormat(arguments.str),rfc_3986_bad_chars,rfc_3986_good_chars);
       
       	return arguments.str;
    }   

    // HMAC-SHA1 Authentication
    private binary function _HMAC_SHA1(
    	required string signKey , required string signMessage
       ) output="false" {
       	var jMsg = JavaCast("string",arguments.signMessage).getBytes("iso-8859-1");
       	var jKey = JavaCast("string",arguments.signKey).getBytes("iso-8859-1");
       	var key = createObject("java","javax.crypto.spec.SecretKeySpec");
       	var mac = createObject("java","javax.crypto.Mac");
       	key = key.init(jKey,"HmacSHA1");
       	mac = mac.getInstance(key.getAlgorithm());
       	mac.init(key);
       	mac.update(jMsg);

       return mac.doFinal();
    }

    //OAuth Signature Base String Function 
    private string function _OauthBaseString (
          required string http_method
        , required string base_uri
        , required struct parameters
    ) output=false{
        // Concatenate http_method & URL-encoded base_uri
        var oauth_signature_base_string = arguments.http_method & "&" & _URLEncodedFormat3986(arguments.base_uri) & "&";
        // Create sorted list of parameter keys 
        var key_list = StructKeyArray(arguments.parameters);

        ArraySort(key_list,"text"); //optional sort, for debugging purpose

        var amp = "";    // first iteration requires no ampersand 
        // Repeat for each parameter 
        for(key in key_list){
           	// Concatenate URL-encoded parameter (key/value pair) 
            oauth_signature_base_string = oauth_signature_base_string & _URLEncodedFormat3986(amp & LCase(key) & "=" & arguments.parameters[key]);
            amp = "&";   // successive iterations require a starting ampersand 
       	}
        //Return with OAuth signature base string 
        return oauth_signature_base_string;
    }
    /* OAUTH REQUEST FUNCTION                                       
     *                                                              
     *   Per OAuth specification, sends specified request and       
     *   parameters to the specified provider (e.g., Twitter).      
     *   Response is returned in a string.  
     */

    private string function _oauthRequest( 
          required string consumer_secret
        , required string token_secret
        , required string http_method
        , required string request_url
        , required struct params
        ) output=false {

        // Backup parameters for later 
        var params_backup = Duplicate(arguments.params);
        // Copy URL variables (if any) to parameters 
        // Parse address and parameters from request URL 
        var request_url_address = arguments.request_url;
        var  request_url_query_string = "";
        var question_mark = Find("?",arguments.request_url,1);

        if (question_mark neq 0){
            request_url_address = Left(arguments.request_url,question_mark-1);
            request_url_query_string = Right(arguments.request_url,(len(arguments.request_url)-question_mark));

            //Repeat for each key/value pair                               
            request_url_query_string = Replace(request_url_query_string, "&&", "PLACEHOLDER_AMPERSAND", "ALL"); // save escaped ampersand (&) symbols 
            request_url_query_string = Replace(request_url_query_string, "==", "PLACEHOLDER_EQUALS", "ALL"); // save escaped equals (=) symbols 
            var params_list = ListChangeDelims(request_url_query_string,",","&,=");
            loop from="1" to=ListLen(params_list) index="index" step="2"{
                // Add parameter to Params structure                            
                arguments.params[ListGetAt(params_list,index)] = ListGetAt(params_list,index+1);
                arguments.params[ListGetAt(params_list,index)] = Replace(arguments.params[ListGetAt(params_list,index)], "PLACEHOLDER_AMPERSAND", "&", "ALL");   // restore escaped ampersand (&) symbols as non-escaped 
                arguments.params[ListGetAt(params_list,index)] = Replace(arguments.params[ListGetAt(params_list,index)], "PLACEHOLDER_EQUALS", "=", "ALL");  // restore escaped equals (=) symbols as non-escaped 
            }
        }
        // Generate signature base string 
        // All parameters must be URL-encoded 
        var key = ""; 
        var param_keys =StructKeyArray(arguments.params);
        for ( key in param_keys ){
            arguments.params[key] = _URLEncodedFormat3986(arguments.params[key])
        }
       	// Get the base string 
        var signature_base_string = _OauthBaseString(arguments.http_method,request_url_address,arguments.params);
        // Generate composite signing key 
        var composite_signing_key = arguments.consumer_secret & "&" & arguments.token_secret;
        //Generate the SHA1 hash 
        var signature = ToBase64(_HMAC_SHA1(composite_signing_key,signature_base_string));
        // Hash (now that we have it) must also be URL encoded 
        signature = _URLEncodedFormat3986(signature);
        // Submit request to provider (e.g., Twitter) 
        // Generate header parameters string 
        var oauth_header = "OAuth ";
        // Parameters (minus URL parameters) 
        var comma = "";
        param_keys = StructKeyArray(params_backup);
        for (key in param_keys){ // use backup list of parameter keys to remove query parameters 
            oauth_header = oauth_header & comma & key & "=""" & params[key] & """"; // ...but use current (URL-encoded) parameter values 
            comma = ", ";
        }
       //Signature 
        oauth_header = oauth_header & ", oauth_signature=""" & signature & """";

         param_keys = StructKeyArray(params);

         var httpResult = "";
        
        http method="post" url=request_url_address result="httpResult" {
            // Header 
            httpparam type="header" name="Authorization" value=oauth_header encoded="no";
            // Parameters 
            for(key in param_keys){
                if(!StructKeyExists(params_backup,key)){   // just the query parameters 
                    httpparam type="formfield" name=key value=params[key] encoded="no";
                }
            }
        }
        if (httpResult.Statuscode neq "200 OK"){
            if ( _getLogger().canError() ) { _getLogger().error( "Twitter error - invalid request : #httpResult.filecontent# "  ); }


            throw(type="TwitterAuthService.inValidOauthRequest", message="Invalid request : #httpResult.filecontent#")

        } else {
        	return httpResult.filecontent;
        }
    }

}
