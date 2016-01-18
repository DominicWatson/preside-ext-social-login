/**
 * social media login extensions to the core website user object
 *
 */
component output=false {
	property name="social_account" relationship="one-to-many" relatedTo="social_account" required=false;
}