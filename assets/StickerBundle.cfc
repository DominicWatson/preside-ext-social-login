component {

	public void function configure( bundle ) {
		// CSS
		bundle.addAsset( id="social-icons-css"                  , path="/css/specific/social-icons/bootstrap-social.css"              );
		bundle.addAsset( id="font-awesome-css"                  , path="/css/specific/font-awesome/font-awesome.css"              );

	bundle.asset( "social-icons-css"   ).dependsOn( "font-awesome-css" );
	}

}