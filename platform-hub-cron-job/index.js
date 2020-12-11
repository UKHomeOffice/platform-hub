'use strict';

const express = require('express');

// Constants
const PORT = 8000;
const HOST = '0.0.0.0';

// App
const app = express();
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
app.get('/', (req, res) => {
  res.send('This would be testing the testing the token expiration reminder cron job');
});

app.listen(PORT, HOST);
console.log(`Running on http://${HOST}:${PORT}`);
