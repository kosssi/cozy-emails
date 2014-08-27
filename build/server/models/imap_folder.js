// Generated by CoffeeScript 1.7.1
var ImapFolder, americano, attributes;

americano = require('americano-cozy');

module.exports = ImapFolder = americano.getModel('ImapFolder', {
  name: String,
  path: String,
  mailbox: String
});

ImapFolder.getByMailbox = function(mailboxID, callback) {
  return ImapFolder.request('byMailbox', {
    key: mailboxID
  }, callback);
};

attributes = {
  id: String,
  name: String,
  path: String,
  specialType: String,
  imapLastFetchedId: {
    type: Number,
    "default": 0
  },
  mailsToBe: Object,
  mailbox: String
};