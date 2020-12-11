'use strict';

require('dotenv').config();

const Job = require('./src/TokenNotificationJob/TokenNotificationJob.js');
const TokenRepository = require('./src/TokenRepository/TokenRepository.js');
const UserEmail = require('./src/UserEmail/UserEmail');
const EmailClient = require('./src/EmailClient/EmailClient');
const NotificationsService = require('./src/NotificationsService/NotificationsService');

const express = require('express');

const app = express();
const tokenRepository =  new TokenRepository();
const userEmail = new UserEmail();
const emailClient =  new EmailClient();

const notificationsService = new NotificationsService(tokenRepository, userEmail, emailClient);

const PORT = 8000;
const HOST = '0.0.0.0';

// sending email to holders of expiring token
const job = new Job(notificationsService);
job.run();

const server = app.listen(PORT, HOST);
console.log(`Running on http://${HOST}:${PORT}`);
  //close the server
  setTimeout(function () {
    server.close();

  }, 1000)
