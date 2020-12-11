'use strict';

require('dotenv').config();
const Job = require('./src/ExpiredTokenNotificationJob/ExpiredTokenNotificationJob.js');
const TokenRepository = require('./src/TokenRepository/TokenRepository.js');
const EmailClient = require('./src/EmailClient/EmailClient');
const express = require('express');

const PORT = 8000;
const HOST = '0.0.0.0';

// App
const app = express();
const tokenRepository =  new TokenRepository();
const emailClient =  new EmailClient();

// sending email to expiring token holders job
const job = new Job(tokenRepository, emailClient);
job.run();


const server = app.listen(PORT, HOST);
console.log(`Running on http://${HOST}:${PORT}`);
  //close the server
  setTimeout(function () {
    server.close();
    // ^^^^^^^^^^^
  }, 1000)
