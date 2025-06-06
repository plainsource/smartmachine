<?php

// Password Plugin options
// -----------------------
// A driver to use for password change. Default: "sql".
// See README file for list of supported driver names.
$config['password_driver'] = 'sql';

// A driver to use for checking password strength. Default: null (disabled).
// See README file for list of supported driver names.
$config['password_strength_driver'] = null;

// Determine whether current password is required to change password.
// Default: false.
$config['password_confirm_current'] = true;

// Require the new password to be a certain length.
// set to blank to allow passwords of any length
//$config['password_minimum_length'] = 8;
$config['password_minimum_length'] = 12;

// Require the new password to have at least the specified strength score.
// Note: Password strength is scored from 1 (week) to 5 (strong).
$config['password_minimum_score'] = 0;

// Enables logging of password changes into logs/password
$config['password_log'] = false;

// Array of login exceptions for which password change
// will be not available (no Password tab in Settings)
$config['password_login_exceptions'] = null;

// Array of hosts that support password changing.
// Listed hosts will feature a Password option in Settings; others will not.
// Example: ['mail.example.com', 'mail2.example.org'];
// Default is NULL (all hosts supported).
$config['password_hosts'] = null;

// Enables saving the new password even if it matches the old password. Useful
// for upgrading the stored passwords after the encryption scheme has changed.
//$config['password_force_save'] = false;
$config['password_force_save'] = true;

// Enables forcing new users to change their password at their first login.
$config['password_force_new_user'] = false;

// Password hashing/crypting algorithm.
// Possible options: des-crypt, ext-des-crypt, md5-crypt, blowfish-crypt,
// sha256-crypt, sha512-crypt, md5, sha, smd5, ssha, ssha256, ssha512, samba, ad, dovecot, clear.
// Also supported are password_hash() algoriths: hash-bcrypt, hash-argon2i, hash-argon2id.
// Default: 'clear' (no hashing)
// For details see password::hash_password() method.
//$config['password_algorithm'] = 'clear';
$config['password_algorithm'] = 'dovecot';

// Additional options for password hashing function(s).
// For password_hash()-based passwords see https://www.php.net/manual/en/function.password-hash.php
// It can be used to set the Blowfish algorithm cost, e.g. ['cost' => 12]
$config['password_algorithm_options'] = [];

// Password prefix (e.g. {CRYPT}, {SHA}) for passwords generated
// using password_algorithm above. Default: empty.
$config['password_algorithm_prefix'] = '';

// Path for dovecotpw/doveadm-pw (if not in the $PATH).
// Used for password_algorithm = 'dovecot'.
// $config['password_dovecotpw'] = '/usr/local/sbin/doveadm pw'; // for dovecot-2.x
//$config['password_dovecotpw'] = '/usr/local/sbin/dovecotpw'; // for dovecot-1.x
$config['password_dovecotpw'] = '/usr/bin/doveadm pw';

// Dovecot password scheme.
// Used for password_algorithm = 'dovecot'.
//$config['password_dovecotpw_method'] = 'CRAM-MD5';
$config['password_dovecotpw_method'] = 'BLF-CRYPT';

// Enables use of password with method prefix, e.g. {MD5}$1$LUiMYWqx$fEkg/ggr/L6Mb2X7be4i1/
// when using password_algorithm=dovecot
//$config['password_dovecotpw_with_method'] = false;
$config['password_dovecotpw_with_method'] = true;

// Number of rounds for the sha256 and sha512 crypt hashing algorithms.
// Must be at least 1000. If not set, then the number of rounds is left up
// to the crypt() implementation. On glibc this defaults to 5000.
// Be aware, the higher the value, the longer it takes to generate the password hashes.
//$config['password_crypt_rounds'] = 50000;

// This option temporarily disables the password change functionality.
// Use it when the users database server is in maintenance mode or something like that.
// You can set it to TRUE/FALSE or a text describing the reason
// which will replace the default.
$config['password_disabled'] = false;

// Various drivers/setups use different format of the username.
// This option allows you to force specified format use. Default: '%u'.
// Supported variables:
//     %u - full username,
//     %l - the local part of the username (in case the username is an email address)
//     %d - the domain part of the username (in case the username is an email address)
// Note: This may no apply to some drivers implementing their own rules, e.g. sql.
$config['password_username_format'] = '%u';

// Options passed when creating Guzzle HTTP client, used to access various external APIs.
// This will overwrite global http_client settings. For example:
// [
//   'timeout' => 10,
//   'proxy' => 'tcp://localhost:8125',
// ]
$config['password_http_client'] = [];


// SQL Driver options
// ------------------
// PEAR database DSN for performing the query. By default
// Roundcube DB settings are used.
// Supported replacement variables:
// %h - user's IMAP hostname
// %n - hostname ($_SERVER['SERVER_NAME'])
// %t - hostname without the first part
// %d - domain (http hostname $_SERVER['HTTP_HOST'] without the first part)
// %z - IMAP domain (IMAP hostname without the first part)
//$config['password_db_dsn'] = '';
$config['password_db_dsn'] = '%<roundcubemail_plugins_password_database_type>s://%<roundcubemail_plugins_password_database_user>s:%<roundcubemail_plugins_password_database_pass>s@%<roundcubemail_plugins_password_database_host>s/%<roundcubemail_plugins_password_database_name>s';

// The SQL query used to change the password.
// The query can contain the following macros that will be expanded as follows:
//      %p is replaced with the plaintext new password
//      %P is replaced with the crypted/hashed new password
//         according to configured password_algorithm
//      %o is replaced with the old (current) password
//      %O is replaced with the crypted/hashed old (current) password
//         according to configured password_algorithm
//      %h is replaced with the imap host (from the session info)
//      %u is replaced with the username (from the session info)
//      %l is replaced with the local part of the username
//         (in case the username is an email address)
//      %d is replaced with the domain part of the username
//         (in case the username is an email address)
// Escaping of macros is handled by this module.
// Default: "SELECT update_passwd(%P, %u)"
//$config['password_query'] = 'SELECT update_passwd(%P, %u)';
$config['password_query'] = 'UPDATE virtual_users SET password=%P WHERE email=%u';

// By default domains in variables are using unicode.
// Enable this option to use punycoded names
$config['password_idn_ascii'] = false;


// Poppassd Driver options
// -----------------------
// The host which changes the password (default: localhost)
// Supported replacement variables:
//   %n - hostname ($_SERVER['SERVER_NAME'])
//   %t - hostname without the first part
//   %d - domain (http hostname $_SERVER['HTTP_HOST'] without the first part)
//   %h - IMAP host
//   %z - IMAP domain without first part
//   %s - domain name after the '@' from e-mail address provided at login screen
$config['password_pop_host'] = 'localhost';

// TCP port used for poppassd connections (default: 106)
$config['password_pop_port'] = 106;


// SASL Driver options
// -------------------
// Additional arguments for the saslpasswd2 call
$config['password_saslpasswd_args'] = '';


// LDAP, LDAP_SIMPLE and LDAP_EXOP Driver options
// -----------------------------------
// LDAP server name to connect to.
// You can provide one or several hosts in an array in which case the hosts are tried from left to right.
// Example: ['ldap1.example.com', 'ldap2.example.com'];
// Default: 'localhost'
$config['password_ldap_host'] = 'localhost';

// LDAP server port to connect to
// Default: '389'
$config['password_ldap_port'] = '389';

// TLS is started after connecting
// Using TLS for password modification is recommended.
// Default: false
$config['password_ldap_starttls'] = false;

// LDAP version
// Default: '3'
$config['password_ldap_version'] = '3';

// LDAP base name (root directory)
// Example: 'dc=example,dc=com'
$config['password_ldap_basedn'] = 'dc=example,dc=com';

// LDAP connection method
// There are two connection methods for changing a user's LDAP password.
// 'user': use user credential (recommended, require password_confirm_current=true)
// 'admin': use admin credential (this mode require password_ldap_adminDN and password_ldap_adminPW)
// Default: 'user'
$config['password_ldap_method'] = 'user';

// LDAP Admin DN
// Used only in admin connection mode
// Default: null
$config['password_ldap_adminDN'] = null;

// LDAP Admin Password
// Used only in admin connection mode
// Default: null
$config['password_ldap_adminPW'] = null;

// LDAP user DN mask
// The user's DN is mandatory and as we only have his login,
// we need to re-create his DN using a mask
// '%login' will be replaced by the current roundcube user's login
// '%name' will be replaced by the current roundcube user's name part
// '%domain' will be replaced by the current roundcube user's domain part
// '%dc' will be replaced by domain name hierarchal string e.g. "dc=test,dc=domain,dc=com"
// Example: 'uid=%login,ou=people,dc=example,dc=com'
$config['password_ldap_userDN_mask'] = 'uid=%login,ou=people,dc=example,dc=com';

// LDAP search DN
// The DN roundcube should bind with to find out user's DN
// based on his login. Note that you should comment out the default
// password_ldap_userDN_mask setting for this to take effect.
// Use this if you cannot specify a general template for user DN with
// password_ldap_userDN_mask. You need to perform a search based on
// users login to find his DN instead. A common reason might be that
// your users are placed under different ou's like engineering or
// sales which cannot be derived from their login only.
$config['password_ldap_searchDN'] = 'cn=roundcube,ou=services,dc=example,dc=com';

// LDAP search password
// If password_ldap_searchDN is set, the password to use for
// binding to search for user's DN. Note that you should comment out the default
// password_ldap_userDN_mask setting for this to take effect.
// Warning: Be sure to set appropriate permissions on this file so this password
// is only accessible to roundcube and don't forget to restrict roundcube's access to
// your directory as much as possible using ACLs. Should this password be compromised
// you want to minimize the damage.
$config['password_ldap_searchPW'] = 'secret';

// LDAP search base
// If password_ldap_searchDN is set, the base to search in using the filter below.
// Note that you should comment out the default password_ldap_userDN_mask setting
// for this to take effect.
$config['password_ldap_search_base'] = 'ou=people,dc=example,dc=com';

// LDAP search filter
// If password_ldap_searchDN is set, the filter to use when
// searching for user's DN. Note that you should comment out the default
// password_ldap_userDN_mask setting for this to take effect.
// '%login' will be replaced by the current roundcube user's login
// '%name' will be replaced by the current roundcube user's name part
// '%domain' will be replaced by the current roundcube user's domain part
// '%dc' will be replaced by domain name hierarchal string e.g. "dc=test,dc=domain,dc=com"
// Example: '(uid=%login)'
// Example: '(&(objectClass=posixAccount)(uid=%login))'
$config['password_ldap_search_filter'] = '(uid=%login)';

// LDAP password hash type
// Standard LDAP encryption type which must be one of: crypt,
// ext_des, md5crypt, blowfish, md5, sha, smd5, ssha, ad, cram-md5 (dovecot style) or clear.
// Set to 'default' if you want to use method specified in password_algorithm option above.
// Multiple password Values can be generated by concatenating encodings with a +. E.g. 'cram-md5+crypt'
// Default: 'crypt'.
$config['password_ldap_encodage'] = 'crypt';

// LDAP password attribute
// Name of the ldap's attribute used for storing user password
// Default: 'userPassword'
$config['password_ldap_pwattr'] = 'userPassword';

// LDAP password force replace
// Force LDAP replace in cases where ACL allows only replace not read
// See http://pear.php.net/package/Net_LDAP2/docs/latest/Net_LDAP2/Net_LDAP2_Entry.html#methodreplace
// Default: true
$config['password_ldap_force_replace'] = true;

// LDAP Password Last Change Date
// Some places use an attribute to store the date of the last password change
// The date is measured in "days since epoch" (an integer value)
// Whenever the password is changed, the attribute will be updated if set (e.g. shadowLastChange)
$config['password_ldap_lchattr'] = '';

// LDAP Samba password attribute, e.g. sambaNTPassword
// Name of the LDAP's Samba attribute used for storing user password
$config['password_ldap_samba_pwattr'] = '';

// LDAP Samba Password Last Change Date attribute, e.g. sambaPwdLastSet
// Some places use an attribute to store the date of the last password change
// The date is measured in "seconds since epoch" (an integer value)
// Whenever the password is changed, the attribute will be updated if set
$config['password_ldap_samba_lchattr'] = '';

// LDAP PPolicy Driver options
// -----------------------------------

// LDAP Change password command - filename of the perl script
// Example: 'change_ldap_pass.pl'
$config['password_ldap_ppolicy_cmd'] = 'change_ldap_pass.pl';

// LDAP URI
// Example: 'ldap://ldap.example.com/ ldaps://ldap2.example.com:636/'
$config['password_ldap_ppolicy_uri'] = 'ldap://localhost/';

// LDAP base name (root directory)
// Example: 'dc=example,dc=com'
$config['password_ldap_ppolicy_basedn'] = 'dc=example,dc=com';

$config['password_ldap_ppolicy_searchDN'] = 'cn=someuser,dc=example,dc=com';

$config['password_ldap_ppolicy_searchPW'] = 'secret';

// LDAP search filter
// Example: '(uid=%login)'
// Example: '(&(objectClass=posixAccount)(uid=%login))'
$config['password_ldap_ppolicy_search_filter'] = '(uid=%login)';

// CA Certificate file if in URI is LDAPS connection
$config['password_ldap_ppolicy_cafile'] = '/etc/ssl/cacert.crt';



// DirectAdmin Driver options
// --------------------------
// The host which changes the password
// Use 'ssl://host' instead of 'tcp://host' when running DirectAdmin over SSL.
// The host can contain the following macros that will be expanded as follows:
//     %h is replaced with the imap host (from the session info)
//     %d is replaced with the domain part of the username (if the username is an email)
$config['password_directadmin_host'] = 'tcp://localhost';

// TCP port used for DirectAdmin connections
$config['password_directadmin_port'] = 2222;


// vpopmaild Driver options
// -----------------------
// The host which changes the password
$config['password_vpopmaild_host'] = 'localhost';

// TCP port used for vpopmaild connections
$config['password_vpopmaild_port'] = 89;

// Timeout used for the connection to vpopmaild (in seconds)
$config['password_vpopmaild_timeout'] = 10;


// cPanel Driver options
// ---------------------
// The cPanel Host name
$config['password_cpanel_host'] = 'host.domain.com';

// The cPanel port to use
$config['password_cpanel_port'] = 2096;


// XIMSS (Communigate server) Driver options
// -----------------------------------------
// Host name of the Communigate server
$config['password_ximss_host'] = 'mail.example.com';

// XIMSS port on Communigate server
$config['password_ximss_port'] = 11024;


// chpasswd Driver options
// ---------------------
// Command to use (see "Sudo setup" in README)
$config['password_chpasswd_cmd'] = 'sudo /usr/sbin/chpasswd 2> /dev/null';


// XMail Driver options
// ---------------------
$config['xmail_host'] = 'localhost';
$config['xmail_user'] = 'YourXmailControlUser';
$config['xmail_pass'] = 'YourXmailControlPass';
$config['xmail_port'] = 6017;


// hMail Driver options
// -----------------------
// Remote hMailServer configuration
// true:  HMailserver is on a remote box (php.ini: com.allow_dcom = true)
// false: Hmailserver is on same box as PHP
$config['hmailserver_remote_dcom'] = false;
// Windows credentials
$config['hmailserver_server'] = [
    'Server'   => 'localhost',      // hostname or ip address
    'Username' => 'administrator',  // windows username
    'Password' => 'password'        // windows user password
];


// pw_usermod Driver options
// --------------------------
// Use comma delimited exlist to disable password change for users.
// See "Sudo setup" in README file.
$config['password_pw_usermod_cmd'] = 'sudo /usr/sbin/pw usermod -h 0 -n';


// DBMail Driver options
// -------------------
// Additional arguments for the dbmail-users call
$config['password_dbmail_args'] = '-p sha512';


// Expect Driver options
// ---------------------
// Location of expect binary
$config['password_expect_bin'] = '/usr/bin/expect';

// Location of expect script (see helpers/passwd-expect)
$config['password_expect_script'] = '';

// Arguments for the expect script. See the helpers/passwd-expect file for details.
// This is probably a good starting default:
//   -telnet -host localhost -output /tmp/passwd.log -log /tmp/passwd.log
$config['password_expect_params'] = '';


// smb Driver options
// ---------------------
// Samba host (default: localhost)
// Supported replacement variables:
// %n - hostname ($_SERVER['SERVER_NAME'])
// %t - hostname without the first part
// %d - domain (http hostname $_SERVER['HTTP_HOST'] without the first part)
$config['password_smb_host'] = 'localhost';
// Location of smbpasswd binary (default: /usr/bin/smbpasswd)
$config['password_smb_cmd'] = '/usr/bin/smbpasswd';

// gearman driver options
// ---------------------
// Gearman host (default: localhost)
$config['password_gearman_host'] = 'localhost';


// Plesk/PPA Driver options
// --------------------
// You need to allow RCP for IP of roundcube-server in Plesk/PPA Panel

// Plesk RCP Host
$config['password_plesk_host'] = '10.0.0.5';

// Plesk RPC Username
$config['password_plesk_user'] = 'admin';

// Plesk RPC Password
$config['password_plesk_pass'] = 'password';

// Plesk RPC Port
$config['password_plesk_rpc_port'] = '8443';

// Plesk RPC Path
$config['password_plesk_rpc_path'] = 'enterprise/control/agent.php';


// kpasswd Driver options
// ---------------------
// Command to use
$config['password_kpasswd_cmd'] = '/usr/bin/kpasswd';


// Modoboa Driver options
// ---------------------
// put token number from Modoboa server
$config['password_modoboa_api_token'] = '';


// Mail-in-a-Box Driver options
// ----------------------------
// the url to the control panel of Mail-in-a-Box, e.g. https://box.example.com/admin/
$config['password_miab_url'] = '';
// name (email) of the admin user used to access api
$config['password_miab_user'] = '';
// password of the admin user used to access api
$config['password_miab_pass'] = '';


// TinyCP
// --------------
// TinyCP host, port, user and pass.
$config['password_tinycp_host'] = '';
$config['password_tinycp_port'] = '';
$config['password_tinycp_user'] = '';
$config['password_tinycp_pass'] = '';

// HTTP-API Driver options
// ---------------------

// Base URL of password change API. HTTPS recommended.
$config['password_httpapi_url'] = 'https://passwordserver.example.org';

// Method (also affects how vars are sent). Default: POST.
// GET is not recommended as passwords will appears in the remote webserver's access log
$config['password_httpapi_method'] = 'POST';

// GET or POST variable in which to put the username
$config['password_httpapi_var_user'] = 'user';

// GET or POST variable in which to put the current password
$config['password_httpapi_var_curpass'] = 'curpass';

// GET or POST variable in which to put the new password
$config['password_httpapi_var_newpass'] = 'newpass';

// HTTP codes other than 2xx are assumed to mean the password changed failed.
// Optionally, if set, this variable additionally checks the body of the 2xx response to
// confirm the change. It's a preg_match regular expression.
$config['password_httpapi_expect'] = '/^ok$/i';


// dovecot_passwdfile
// ------------------
$config['password_dovecot_passwdfile_path'] = '/etc/mail/imap.passwd';


// Mailcow driver options
// ----------------------
$config['password_mailcow_api_host'] = 'localhost';
$config['password_mailcow_api_token'] = '';