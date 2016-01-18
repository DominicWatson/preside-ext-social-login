/**
 * social media account
 *
 */
component output=false {
	property name="social_id"   type="string" required="true";
	property name="firstname"   type="string" required="true";
	property name="lastname"    type="string" required="true";
	property name="email"       type="string" required="true";
	property name="social_link" type="string" required="false";
	property name="image_link"  type="string" required="false";
	property name="gender" 		type="string" required="false";
	property name="type" 		type="string" required="true";
	property name="website_user" relationship="many-to-one" relatedTo="website_user" required=false;
}