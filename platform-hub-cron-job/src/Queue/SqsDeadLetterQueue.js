// Load the AWS SDK for Node.js
const AWS = require('aws-sdk');
// Set the region 
AWS.config.update({region: 'REGION'});

// Create the SQS service object
const sqs = new AWS.SQS({apiVersion: '2012-11-05'});

var params = {
 Attributes: {
  "RedrivePolicy": "{\"deadLetterTargetArn\":\"arn:aws:sqs:eu-west-1:670930646103:phub-token-expiration-reminder-queue\",\"maxReceiveCount\":\"10\"}",
 },
 QueueUrl: "https://sqs.eu-west-1.amazonaws.com/670930646103/phub-notifications-bounces-queue"
};

sqs.setQueueAttributes(params, function(err, data) {
  if (err) {
    console.log("Error", err);
  } else {
    console.log("Success", data);
  }
});