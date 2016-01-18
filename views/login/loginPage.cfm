<cfscript>
enableWebsiteLogin  = isBoolean(prc.enableWebsiteLogin)?prc.enableWebsiteLogin:false;
enableFacebookLogin = isBoolean(prc.enableFacebookLogin)?prc.enableFacebookLogin:false;
enableTwitterLogin  = isBoolean(prc.enableTwitterLogin)?prc.enableTwitterLogin:false;
enableGoogleLogin   = isBoolean(prc.enableGoogleLogin)?prc.enableGoogleLogin:false;
</cfscript>

<cfoutput>	
	<div class="row">
		<cfif enableWebsiteLogin>
				
			<div class="col-md-6 col-sm-12 col-xs-12">
	            <form action="#event.buildLink( linkTo="login.attemptLogin" )#" method="post" class="login-form">
	              <div class="form-field">
	                <label for="txt-username">Username <span class="required">*</span></label>
	                <input type="text" name="loginid" id="txt-username" class="form-control">
	              </div>
	              <div class="form-field password">
	                <label for="txt-password">Password <span class="required">*</span></label>
	                <input type="password" id="txt-password" name="password" class="form-control">
	              </div>
	              <div class="form-field remember-me">
	                <input type="checkbox" id="chk-remember" name="rememberMe" value="1">
	                <label for="chk-remember">Keep me logged in</label>
	                
	              </div>
	              <div class="login-button">
	                <button type="submit" class="btn" > Login </button>
	                <a href="#event.buildLink( page="forgotten_password" )#" class="pull-right">Forgotten password</a>
	                <p>&nbsp;</p>
	              </div>
	            </form>
	        </div>
	    </cfif>
   
		<div class="col-md-5 col-sm-12 col-xs-12 social-buttons">
		<p>
			<cfif enableFacebookLogin>
				<a class="btn btn-block btn-social  btn-lg btn-facebook" href="#event.buildLink(linkTo="login.social",querystring="type=facebook")#">
				  <span class="fa fa-facebook"></span>
				  Login with Facebook
				</a>
			</cfif>
			<cfif enableTwitterLogin>
				<a class="btn btn-block btn-social  btn-lg btn-twitter" href="#event.buildLink(linkTo="login.social",querystring="type=twitter")#">
				  <span class="fa fa-twitter"></span>
				  Login with Twitter
				</a>
			</cfif>
			<cfif enableGoogleLogin>
				<a class="btn btn-block btn-social  btn-lg btn-google" href="#event.buildLink(linkTo="login.social",querystring="type=google")#">
				  <span class="fa fa-google"></span>
				  Login in with Google
				</a>
			</cfif>
		</p>
		</div>

	</div>
</cfoutput>	