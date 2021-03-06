// Generated by CoffeeScript 1.9.3
var CLIENT_ID, CLIENT_SECRET, PasswordEncryptedError, getXoauth2Generator, log, makeIMAPConfig, xOAuthCache, xoauth2;

xoauth2 = require('xoauth2');

log = require('../utils/logging')({
  prefix: 'imap:oauth'
});

PasswordEncryptedError = require('../utils/errors').PasswordEncryptedError;

xOAuthCache = {};

CLIENT_ID = '260645850650-2oeufakc8ddbrn8p4o58emsl7u0r0c8s' + '.apps.googleusercontent.com';

CLIENT_SECRET = '1gNUceDM59TjFAks58ftsniZ';

getXoauth2Generator = function(account) {
  var generator, timeout;
  if (!xOAuthCache[account.id]) {
    log.info("XOAUTH GENERATOR FOR " + account.label);
    timeout = 1000 * account.oauthTimeout - Date.now();
    timeout = Math.floor(timeout / 1000);
    timeout = Math.max(timeout, 0);
    generator = xoauth2.createXOAuth2Generator({
      user: account.login,
      clientSecret: CLIENT_SECRET,
      clientId: CLIENT_ID,
      refreshToken: account.oauthRefreshToken,
      accessToken: account.oauthAccessToken,
      timeout: timeout
    });
    generator.on('token', function(arg) {
      var accessToken, timeout, user;
      user = arg.user, accessToken = arg.accessToken, timeout = arg.timeout;
      return account.updateAttributes({
        oauthAccessToken: accessToken,
        oauthTimeout: generator.timeout
      }, function(err) {
        log.info("UPDATED ACCOUNT OAUTH " + account.label);
        if (err) {
          return log.warn(err);
        }
      });
    });
    xOAuthCache[account.id] = generator;
  }
  return xOAuthCache[account.id];
};

module.exports.forceOauthRefresh = function(account, callback) {
  log.info("FORCE OAUTH REFRESH");
  return getXoauth2Generator(account).generateToken(callback);
};

module.exports.makeSMTPConfig = function(account) {
  var options;
  options = {
    port: account.smtpPort,
    host: account.smtpServer,
    secure: account.smtpSSL,
    ignoreTLS: !account.smtpTLS,
    tls: {
      rejectUnauthorized: false
    }
  };
  if ((account.smtpMethod != null) && account.smtpMethod !== 'NONE') {
    options.authMethod = account.smtpMethod;
  }
  if (account.oauthProvider === 'GMAIL') {
    options.service = 'gmail';
    options.auth = {
      xoauth2: getXoauth2Generator(account)
    };
  } else {
    options.auth = {
      user: account.smtpLogin || account.login,
      pass: account.smtpPassword || account.password
    };
  }
  return options;
};

module.exports.makeIMAPConfig = makeIMAPConfig = function(account, callback) {
  var generator;
  if (account.oauthProvider === "GMAIL") {
    generator = getXoauth2Generator(account);
    return generator.getToken(function(err, token) {
      if (err) {
        return callback(err);
      }
      return callback(null, {
        user: account.login,
        xoauth2: token,
        host: "imap.gmail.com",
        port: 993,
        tls: true,
        tlsOptions: {
          rejectUnauthorized: false
        }
      });
    });
  } else if (account._passwordStillEncrypted) {
    return callback(new PasswordEncryptedError(account));
  } else {
    return callback(null, {
      user: account.imapLogin || account.login,
      password: account.password,
      host: account.imapServer,
      port: parseInt(account.imapPort),
      tls: (account.imapSSL == null) || account.imapSSL,
      tlsOptions: {
        rejectUnauthorized: false
      },
      autotls: 'required'
    });
  }
};
