var ARCHIVE = "Archivieren";
var PROCESSED = "_archived_processed";
var MAX_RUN_MS = 4.5 * 60 * 1000;   // stay under the 6-minute execution cap

// batchModify documents a 1000-id limit but returns "Internal error
// encountered" well below that. 50 is a size it handles reliably.
var CHUNK = 50;

// newer_than:1d was the bug: it limited every run to the last 24 hours, so
// the backlog was never touched. after:2026/03/01 is gone for the same
// reason — put it back only if mail before that date is meant to stay put.
//
// -has:userlabels is what narrows this to strays. Without it the query
// matches every archived message, so the script walks the whole mailbox
// and relabels mail that is already filed. Drop it only if the intent is
// "every archived message carries Archivieren", not "nothing is unfiled".
var QUERY = "-in:inbox -in:sent -in:drafts -has:userlabels" +
            " -label:" + PROCESSED +
            " -in:trash -in:spam -in:chats";


/**
 * Label every archived message that is not yet filed.
 * Safe to run repeatedly: it resumes where it stopped.
 */
function labelArchived() {
  ensureLabel_(ARCHIVE);
  ensureHiddenLabel_(PROCESSED);

  var addIds = [getLabelId_(ARCHIVE), getLabelId_(PROCESSED)];
  var start = Date.now();
  var total = 0;

  while (Date.now() - start < MAX_RUN_MS) {
    // No pageToken needed: a processed message gains _archived_processed and
    // drops out of the result set, so the next page is always page one.
    var res = Gmail.Users.Messages.list("me", { q: QUERY, maxResults: 500 });
    var msgs = res.messages || [];

    if (msgs.length === 0) {
      console.log("done — %s messages labelled this run", total);
      return total;
    }

    for (var i = 0; i < msgs.length; i += CHUNK) {
      if (Date.now() - start >= MAX_RUN_MS) break;
      var ids = msgs.slice(i, i + CHUNK).map(function (m) { return m.id; });
      total += applyLabels_(ids, addIds);
      Utilities.sleep(150);         // stay clear of the rate limiter
    }
  }

  console.log("time budget reached — %s labelled, more remain", total);
  return total;
}


/**
 * Label one chunk. Retries the batch, then falls back to one call per
 * message so a single poisoned id cannot stall the whole run.
 * Returns how many messages were actually labelled.
 */
function applyLabels_(ids, addIds) {
  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      Gmail.Users.Messages.batchModify({ ids: ids, addLabelIds: addIds }, "me");
      return ids.length;
    } catch (e) {
      Utilities.sleep(1000 * Math.pow(2, attempt));   // 1s, 2s, 4s
    }
  }

  var done = 0;
  for (var i = 0; i < ids.length; i++) {
    try {
      Gmail.Users.Messages.modify({ addLabelIds: addIds }, "me", ids[i]);
      done++;
    } catch (e) {
      console.log("skipped %s: %s", ids[i], e.message);
    }
  }
  return done;
}


/**
 * Count what is still unfiled. Touches nothing.
 */
function countUnprocessed() {
  var res = Gmail.Users.Messages.list("me", { q: QUERY, maxResults: 500 });
  var n = (res.messages || []).length;
  console.log(n < 500 ? "exactly %s unfiled" : "at least %s unfiled", n);
  return n;
}


/**
 * Run labelArchived() hourly. Call once; it clears its own duplicates.
 */
function installHourlyTrigger() {
  ScriptApp.getProjectTriggers().forEach(function (t) {
    if (t.getHandlerFunction() === "labelArchived") ScriptApp.deleteTrigger(t);
  });
  ScriptApp.newTrigger("labelArchived").timeBased().everyHours(1).create();
  console.log("hourly trigger installed");
}


function getLabelId_(name) {
  var labels = Gmail.Users.Labels.list("me").labels;
  for (var i = 0; i < labels.length; i++) {
    if (labels[i].name === name) return labels[i].id;
  }
  return null;
}


function ensureLabel_(name) {
  if (!GmailApp.getUserLabelByName(name)) {
    GmailApp.createLabel(name);
  }
}


function ensureHiddenLabel_(name) {
  if (!getLabelId_(name)) {
    Gmail.Users.Labels.create({
      name: name,
      labelListVisibility: "labelHide",
      messageListVisibility: "hide"
    }, "me");
  }
}
