component extends="preside.system.handlers.Login" {
	property name="websiteLoginService"        inject="websiteLoginService";
	property name="passwordPolicyService"      inject="passwordPolicyService";
	property name="SocialAuthService" 	       inject="SocialAuthService";
	property name="TwitterAuthService" 	       inject="TwitterAuthService";
	property name="systemConfigurationService" inject="systemConfigurationService";

	private string function loginPage( event, rc, prc, args={} ) output=false {
		event.include( "social-icons-css" );
		var socialConfig = systemConfigurationService.getCategorySettings( "social-login" );

		prc.enableWebsiteLogin  = socialConfig.website_login?:false;
		prc.enableFacebookLogin = socialConfig.facebook_login?:false;
		prc.enableTwitterLogin  = socialConfig.twitter_login?:false;
		prc.enableGoogleLogin   = socialConfig.google_login?:false;

		return super.loginPage(argumentCollection=arguments);
	}

	public void function social( event, rc, prc ) output=false {
		//announceInterception( "preAttemptSocialLogin" );
		event.include( "social-icons-css" );

		if ( websiteLoginService.isLoggedIn() && !websiteLoginService.isAutoLoggedIn() ) {
			setNextEvent( url=_getDefaultPostLoginUrl( argumentCollection=arguments ) );
		}

		var type = rc.type?:"";

		switch(type){
			case 'facebook':
				socialAuthService.initiateFacebookLogin(redirectURI=event.buildLink(linkTo="/login/auth/",querystring="type=facebook"));
			break;
			case 'twitter':
				TwitterAuthService.initiateTwitterLogin(redirectURI=event.buildLink(linkTo="/login/auth/",querystring="type=twitter"));
			break;
			case 'google':
				socialAuthService.initiateGoogleLogin(redirectURI=event.buildLink(linkTo="/login/auth/",querystring="type=google"));
			break;
			default:
				throw (type="SocialLogin.error", message="Social login (#type#) not found.");
			break;
		}
	}

	public void function auth( event, rc, prc ) output=false {
		announceInterception( "preAttemptSocialLogin" );

		if ( websiteLoginService.isLoggedIn() && !websiteLoginService.isAutoLoggedIn() ) {
			setNextEvent( url=_getDefaultPostLoginUrl( argumentCollection=arguments ) );
		}

		var type = rc.type?:"";

		var socialAccount = {};

		switch(type){
			case 'facebook':
					socialAccount = socialAuthService.authoriseFacebookLogin(
						  redirectURI = event.buildLink(linkTo="/login/auth/",querystring="type=#type#")
						, code = event.getValue("code")
						, state  =  event.getValue("state")
						
					);

			break;
			case 'twitter':
				socialAccount = TwitterAuthService.authoriseTwitterLogin(
						  oauth_token    = event.getValue("oauth_token")
						, oauth_verifier = event.getValue("oauth_verifier")
						
					);
			break;
			case 'google':
				socialAccount = socialAuthService.authoriseGoogleLogin(
						  redirectURI = event.buildLink(linkTo="/login/auth/",querystring="type=#type#")
						, code = event.getValue("code")
						, state  =  event.getValue("state")
						
					);
			break;
			default:
				throw (type="SocialAuth.error", message="Social login (#type#) not found.");
			break;
		}


		


		loggedIn = socialAuthService.socialLogin( socialAccount );

		var postLoginUrl = Len( Trim( rc.postLoginUrl ?: "" ) ) ? rc.postLoginUrl : websiteLoginService.getPostLoginUrl( cgi.http_referer );
		var rememberMe   = _getRememberMeAllowed() && IsBoolean( rc.rememberMe ?: "" ) && rc.rememberMe;
		


		if ( loggedIn ) {
			announceInterception( "onLoginSuccess"  );

			websiteLoginService.clearPostLoginUrl();
			setNextEvent( url=postLoginUrl );
		}

		announceInterception( "onLoginFailure"  );

		websiteLoginService.setPostLoginUrl( postLoginUrl );
		setNextEvent( url=event.buildLink( page="login" ), persistStruct={
			  loginId      = loginId
			, password     = password
			, postLoginUrl = postLoginUrl
			, rememberMe   = rememberMe
			, message      = "LOGIN_FAILED"
		} );
	}

}
