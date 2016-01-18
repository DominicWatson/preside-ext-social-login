component output=false singleton=true {

// CONSTRUCTOR
	/**
	 * @sessionStorage.inject             coldbox:plugin:sessionStorage
	 * @systemConfigurationService.inject systemConfigurationService
	 * @logger.inject                     logbox:logger:SocialAuthService
	 * @socialAccountDao.inject      	  presidecms:object:social_account
	 * @websiteLoginService.inject        websiteLoginService
	 * @userDao.inject                    presidecms:object:website_user
	 */
	public any function init( required any systemConfigurationService, required any logger, required any sessionStorage, required any socialAccountDao, required any websiteLoginService, required any userDao ) output=false {
		_setSystemConfigurationService( arguments.systemConfigurationService );
		_setLogger(                     arguments.logger                     );
		_setSessionStorage(             arguments.sessionStorage             );
		_setSocialAccountDao(           arguments.socialAccountDao           );
		_setWebsiteLoginService(        arguments.websiteLoginService        );
		_setUserDao(			        arguments.userDao 			         );
		_setSessionKey( 				"social_login" 						 );

		
		return this;
	}

	// INITIAL OAUTH CALL TO FACEBOOK,LINKEDIN OR GOOGLE 
    public function initiateOAuthLogin(
          required string loginUrlBase
        , required string loginClientID
        , required string loginRedirectURI
        , required string loginScope
    ) output=false{
    	var socialSession = _getSessionStorage().getVar(_getSessionKey());
        var socialSession = { login_state = socialSession.login_state?:createUUID() };

        _getSessionStorage().setVar(name=_getSessionKey(),value=socialSession);
        var urlString = "";
        urlString = urlString & arguments.loginUrlBase;
        urlString = urlString & "?client_id=";
        urlString = urlString & arguments.loginClientID;
        urlString = urlString & "&redirect_uri=";
        urlString = urlString & arguments.loginRedirectURI;
        urlString = urlString & "&state=";
        urlString = urlString & socialSession.login_state;
        urlString = urlString & "&scope=";
        urlString = urlString & arguments.loginScope;
        urlString = urlString & "&response_type=code";
        location url=urlString addtoken="false";

    }

    // AUTHORISATION CALL TO FACEBOOK,LINKEDIN OR GOOGLE            
    public function authoriseOauthLogin(
          required string authUrlBase
        , required string authRedirectURI
        , required string authMethod
        , required string authCode
        , required string authClientId
        , required string authClientSecret
        , required string authGrantType
        ){
        var urlBody = "";
        var httpResult = "";
        urlBody = urlBody & "code=";
        urlBody = urlBody & arguments.authCode;
        urlBody = urlBody & "&redirect_uri=";
        urlBody = urlBody & arguments.authRedirectURI;
        urlBody = urlBody & "&client_id=";
        urlBody = urlBody & arguments.authClientId;
        urlBody = urlBody & "&client_secret=";
        urlBody = urlBody & arguments.authClientSecret;
        urlBody = urlBody & "&grant_type=";
        urlBody = urlBody & arguments.authGrantType;
        // Get the ACCESS TOKEN 
        http url=arguments.authUrlBase result="httpResult" method=arguments.authMethod resolveurl="true" {
            httpparam type="header" name="Content-Type" value="application/x-www-form-urlencoded";
            httpparam type="body" value=urlBody;
        }
        return httpResult;
    }

    //FACEBOOK
    public function initiateFacebookLogin(required string redirectURI) output=false{

    var config = _getSystemConfigurationService().getCategorySettings( "social-login" );
    
    initiateOAuthLogin(
    			loginUrlBase = "https://www.facebook.com/dialog/oauth",
				loginClientID = config.facebook_appid,
				loginRedirectURI = arguments.redirectURI,
				loginScope = "public_profile,email"
		);
	}

	public function authoriseFacebookLogin(required string code,required string redirectURI){
		var config = _getSystemConfigurationService().getCategorySettings( "social-login" );
  

		var fbAuthResult = authoriseOauthLogin(
	          authUrlBase      = "https://graph.facebook.com/oauth/access_token"
	        , authRedirectURI  = arguments.redirectURI
	        , authMethod       = "post"
	        , authCode         = arguments.code
	        , authClientId     = config.facebook_appid
	        , authClientSecret = config.facebook_secret
	        , authGrantType    = "authorization_code"
        
    	);

    	if(Find(fbAuthResult.status_code,"200")){
    		//get auth token 
    		var part1 = listGetAt(fbAuthResult.filecontent, 1, "&");
			var access_token = listGetAt(part1, 2, "=");

    		var userInfo = _facebookGetUserInfo(access_token);
    		var socialSession = _getSessionStorage().getVar(_getSessionKey());
    		
    		socialSession.facebook_access_token = access_token; 
    		
    		_getSessionStorage().setVar(name=_getSessionKey(),value=socialSession);
    		if(structCount(userInfo)){
	    		var socialUser = {
	    			  social_id   = userInfo.id
	    			, label 	  = userInfo.name
					, firstname   = userInfo.first_name
					, lastname    = userInfo.last_name
					, email       = userInfo.email
					, social_link = userInfo.link?:""
					, image_link  = ""
					, gender 	  = userInfo.gender?:""
					, type 		  = "facebook"
	    		}

	    		return _createSocialAccount(socialUser);
    		} else {
	    		if ( _getLogger().canError() ) { _getLogger().error( "Facebook error : unable to retrieve user info. "  ); }

	    		throw( type="SocialAuthService.facebook.error", message="Facebook error : unable to retrieve user info. " );

    		}


    	} else {
    		var result = deserializeJSON(fbAuthResult.filecontent);

    		if ( _getLogger().canError() ) { _getLogger().error( "Facebook error #result.error.type?:""# : #result.error.message?:"Facebook authorisation error."# "  ); }

    		throw( type="SocialAuthService.facebook.#result.error.type?:"error"#", message=result.error.message?:"Facebook authorisation error.", code=result.error.code?:0 );

    	}

    	return {};
	}

	private function _facebookGetUserInfo(required string access_token){

		var userInfo = {};

		http url="https://graph.facebook.com/me?access_token=#arguments.access_token#" result="userInfo";

		if (isJSON(userInfo.filecontent)){
			return deserializeJSON(userInfo.filecontent);
		} else {
			return {};
		}
	}

	//GOOGLE
    public function initiateGoogleLogin(required string redirectURI) output=false{

    var config = _getSystemConfigurationService().getCategorySettings( "social-login" );
    
    initiateOAuthLogin(
    			loginUrlBase = "https://accounts.google.com/o/oauth2/auth",
				loginClientID = config.google_client_id,
				loginRedirectURI = arguments.redirectURI,
				loginScope = "https://www.googleapis.com/auth/userinfo.email"
		);
	}

	public function authoriseGoogleLogin(required string code,required string redirectURI){
		var config = _getSystemConfigurationService().getCategorySettings( "social-login" );
  

		var gAuthResult = authoriseOauthLogin(
	          authUrlBase      = "https://accounts.google.com/o/oauth2/token"
	        , authRedirectURI  = arguments.redirectURI
	        , authMethod       = "post"
	        , authCode         = arguments.code
	        , authClientId     = config.google_client_id
	        , authClientSecret = config.google_secretkey
	        , authGrantType    = "authorization_code"
    
    	);

    	if(Find(gAuthResult.status_code,"200")){
    		//get auth token 
    		var authResult = deserializeJSON(gAuthResult.filecontent);
    		var access_token = authResult.access_token?:"";

    		var userInfo =  _googleGetUserInfo(access_token);

    		var socialSession = _getSessionStorage().getVar(_getSessionKey());	
    		
    		socialSession.google_access_token = access_token; 

    		_getSessionStorage().setVar(name=_getSessionKey(),value=socialSession);

    		if(structCount(userInfo)){
	    		var socialUser = {
	    			  social_id   = userInfo.id
	    			, label 	  = userInfo.name
					, firstname   = userInfo.given_name
					, lastname    = userInfo.family_name
					, email       = userInfo.email
					, social_link = userInfo.link?:""
					, image_link  = userInfo.picture?:""
					, gender 	  = userInfo.gender?:""
					, type 		  = "google"
	    		}

	    		return _createSocialAccount(socialUser);
    		} else {
	    		if ( _getLogger().canError() ) { _getLogger().error( "Facebook error : unable to retrieve user info. "  ); }

	    		throw( type="SocialAuthService.facebook.error", message="Facebook error : unable to retrieve user info. " );

    		}


    	} else {
    		var result = deserializeJSON(gAuthResult.filecontent);

    		if ( _getLogger().canError() ) { _getLogger().error( "Facebook error #result.error?:""# : #result.error_description?:"Google authorisation error."# "  ); }

    		throw( type="SocialAuthService.google.#result.error?:"error"#", message=result.error_description?:"Google authorisation error." );

    	}

    	return {};
	}
	private function _googleGetUserInfo(required string access_token){

		var userInfo = {};

		http url="https://www.googleapis.com/oauth2/v1/userinfo" result="userInfo"{
			httpparam type="header" name="Authorization" value="OAuth #arguments.access_token#";
			httpparam type="header" name="GData-Version" value="3";
		}

		if (isJSON(userInfo.filecontent)){
			return deserializeJSON(userInfo.filecontent);
		} else {
			return {};
		}
	}

	private function _createSocialAccount(required struct socialUser){
		//check if social account exists 
		var exists = _getSocialAccountDao().selectData(  
					  filter 	   = "social_id = :social_id"
					, filterParams = {social_id = arguments.socialUser.social_id });

		if(exists.recordcount){
			_getSocialAccountDao().updateData( id=exists.id, data=arguments.socialUser );
			
			return exists.id;

		} else {
			//create new record
			var newRecord = _getSocialAccountDao().insertData(arguments.socialUser);

			return newRecord

		}

	}

	//login functions
	public function socialLogin(required string socialAccountId){
		//check if social account links to existing user 
		var socialAccount = _getSocialAccountDao().selectData(  
					  filter 	   = "id = :id"
					, filterParams = {"id" = arguments.socialAccountId });



		var user = _getUserDao().selectData(  
					  filter 	   = "social_account.id = :social_account.id or website_user.email_address = :email_address"
					, filterParams = {
										  "social_account.id" = socialAccount.id
										, email_address 	  = socialAccount.email

									 });

		var userId = "";




		if(!user.recordcount){
			//create new record
			var newUser = {
				  login_id      = socialAccount.email
				, email_address = socialAccount.email
				, display_name  = socialAccount.firstname & " " & socialAccount.lastname

			}
			if(socialAccount.type eq "twitter" && !Len(newUser.login_id)){
				newUser.login_id = socialAccount.label; //set it as twitter handler if there is no email
			}


			userId = _getUserDao().insertData(newUser);



			//update social account
			_getSocialAccountDao().updateData(id=socialAccount.id, data={website_user = userId})

			

		} else {
			userId = user.id;
			
			//update the social account to link to website user
			if(!Len(socialAccount.website_user)){
				_getSocialAccountDao().updateData(id=socialAccount.id, data={website_user = userId})	
			}
			
		}

		return _getWebsiteLoginService().impersonate(userId);



	}



// GETTERS AND SETTERS
	private any function _getSystemConfigurationService() output=false {
		return _systemConfigurationService;
	}
	private void function _setSystemConfigurationService( required any systemConfigurationService ) output=false {
		_systemConfigurationService = arguments.systemConfigurationService;
	}

	private any function _getLogger() output=false {
		return _logger;
	}
	private void function _setLogger( required any logger ) output=false {
		_logger = arguments.logger;
	}

	private any function _getSessionStorage() {
		return _sessionStorage;
	}
	private void function _setSessionStorage( required any sessionStorage ) {
		_sessionStorage = arguments.sessionStorage;
	}

	private any function _getSocialAccountDao() {
		return _socialAccountDao;
	}
	private void function _setSocialAccountDao( required any socialAccountDao ) {
		_socialAccountDao = arguments.socialAccountDao;
	}

	private any function _getWebsiteLoginService() output=false {
		return _websiteLoginService;
	}
	private void function _setWebsiteLoginService( required any websiteLoginService ) output=false {
		_websiteLoginService = arguments.websiteLoginService;
	}

	private any function _getUserDao() {
		return _userDao;
	}
	private void function _setUserDao( required any userDao ) {
		_userDao = arguments.userDao;
	}

	private string function _getSessionKey() {
		return _sessionKey;
	}
	private void function _setSessionKey( required string sessionKey ) {
		_sessionKey = arguments.sessionKey;
	}

}
