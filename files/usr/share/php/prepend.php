<?php
/**
 * This is heavily inspired by https://raw.githubusercontent.com/kalabox/kalabox-app-pantheon/v2.1/app/config/php/prepend.php
 *
 * The original license can be found at https://github.com/kalabox/kalabox-app-pantheon/blob/v2.1/LICENSE.txt
 */

if (getenv("DDEV_PROVIDER") == "pantheon") {
    if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https') {
    // Let drupal know when to generate absolute links as https.
    // Used in drupal_settings_initialize()
    $_SERVER['HTTPS'] = 'on';
    $_SERVER['HTTP_X_SSL'] = 'ON';
    }


    define('PANTHEON_DATABASE_HOST', getenv('DB_HOST'));
    define('PANTHEON_DATABASE_PORT', getenv('DB_PORT'));
    define('PANTHEON_DATABASE_USERNAME', getenv('DB_USER'));
    define('PANTHEON_DATABASE_PASSWORD', getenv('DB_PASSWORD'));
    define('PANTHEON_DATABASE_DATABASE', getenv('DB_NAME'));
    $_ENV['DB_HOST'] = PANTHEON_DATABASE_HOST;
    $_ENV['DB_PORT'] = PANTHEON_DATABASE_PORT;
    $_ENV['DB_USER'] = PANTHEON_DATABASE_USERNAME;
    $_ENV['DB_PASSWORD'] = PANTHEON_DATABASE_PASSWORD;
    $_ENV['DB_NAME'] = PANTHEON_DATABASE_DATABASE;


    define('PRESSFLOW_SETTINGS', getenv('PRESSFLOW_SETTINGS'));
    $_SERVER['PRESSFLOW_SETTINGS'] = PRESSFLOW_SETTINGS;

    $_ENV['PANTHEON_ENVIRONMENT'] = 'ddev';

    // Set $HOME to empty since this is used as a prefix for the /tmp path.
    $_ENV['HOME'] = $_SERVER['HOME'] = '';

    $_ENV['DRUPAL_HASH_SALT'] = getenv('DRUPAL_HASH_SALT');

    $_ENV['AUTH_KEY'] = getenv('AUTH_KEY');
    $_ENV['SECURE_AUTH_KEY'] = getenv('SECURE_AUTH_KEY');
    $_ENV['LOGGED_IN_KEY'] = getenv('LOGGED_IN_KEY');
    $_ENV['AUTH_SALT'] = getenv('AUTH_SALT');
    $_ENV['SECURE_AUTH_SALT'] = getenv('SECURE_AUTH_SALT');
    $_ENV['LOGGED_IN_SALT'] = getenv('LOGGED_IN_SALT');
    $_ENV['NONCE_SALT'] = getenv('NONCE_SALT');
    $_ENV['NONCE_KEY'] = getenv('NONCE_KEY');

    $base_url = $_ENV['DDEV_URL'];
    /**
    * We need to set this on Drupal 8 to make sure we are getting
    * properly redirected to install.php in the event that the
    * user does not have the needed core tables.
    * @todo: how does this check impact performance?
    *
    * Issue: https://github.com/pantheon-systems/drops-8/issues/139
    *
    */
    if (
    isset($_ENV['FRAMEWORK']) &&
    $_ENV['FRAMEWORK'] == 'drupal8' &&
    (empty($GLOBALS['install_state'])) &&
    php_sapi_name() != "cli"
    ) {

    /* Connect to an ODBC database using driver invocation */
    $dsn = 'mysql:dbname=' . $_ENV['DB_NAME'] . ';host=' . $_ENV['DB_HOST'] . ';port=' . $_ENV['DB_PORT'];
    $user = $_ENV['DB_USER'];
    $password = $_ENV['DB_PASSWORD'];

    try {
        $dbh = new PDO($dsn, $user, $password);
    } catch (PDOException $e) {
        echo 'Connection failed: ' . $e->getMessage();
    }

    /**
    * Check to see if the `users` table exists and if it does not set
    * PANTHEON_DATABASE_STATE to `empty` to allow for correct redirect to
    * install.php. This is for users who create sites on Pantheon but
    * don't go through the database setup before they pull them down
    * on Kalabox.
    *
    * Issue: https://github.com/pantheon-systems/drops-8/issues/139
    *
    */
    if ((gettype($dbh->exec("SELECT count(*) FROM users")) == 'integer') != 1) {
        $_SERVER['PANTHEON_DATABASE_STATE'] = 'empty';
    }

    // And now we're done; close it up!
    $dbh = null;

    }
}