'use strict';
const fs = require('node:fs');
// Return true while this instance is willing to receive Service requests.
// A marker affects this container only; deleting it restores readiness.
function isReady(markerPath = process.env.READINESS_BLOCK_FILE) {
  if (!markerPath) return true;
  return !fs.existsSync(markerPath);
}
module.exports = { isReady };
