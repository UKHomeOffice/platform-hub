'use strict';

require('dotenv').config();

const Job = require('./src/NonExpiringTokenNotificationJob/NonExpiringTokenNotificationJob.js');
const TokenRepository = require('./src/TokenRepository/TokenRepository.js');
const EmailClient = require('./src/EmailClient/EmailClient');
const UserEmail = require('./src/UserEmail/UserEmail');

const express = require('express');
const app = express();
const tokenRepository =  new TokenRepository();
const emailClient =  new EmailClient();
const userEmail = new UserEmail();

const PORT = 8000;
const HOST = '0.0.0.0';

// sending email to holders of expiring token
const job = new Job(tokenRepository, userEmail, emailClient);
job.run();


const server = app.listen(PORT, HOST);
console.log(`Running on http://${HOST}:${PORT}`);
  //close the server
  setTimeout(function () {
    server.close();

  }, 1000)
