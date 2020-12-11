var AWS = require('aws-sdk');
// Set the region
AWS.config.update({region: 'eu-west-2'});

// Create sendEmail params
var params = {
  Destination: { /* required */
    ToAddresses: [
      'EMAIL_ADDRESS',
      /* more items */
    ]
  },
  Message: { /* required */
    Body: { /* required */
      Html: {
       Charset: "UTF-8",
       Data: "To Platform user <br> <br> Your token is due to expire, please go to the ACP Hub to regenerate your token.<br> <br>Thanks <br> ACP Team"
      },
      Text: {
       Charset: "UTF-8",
       Data: "TEXT_FORMAT_BODY"
      }
     },
     Subject: {
      Charset: 'UTF-8',
      Data: 'Reminder: Expiring Token'
     }
    },
  Source: 'EMAIL_ADDRESS' /* required */
};

// Create the promise and SES service object
var sendPromise = new AWS.SES({apiVersion: '2010-12-01'}).sendEmail(params).promise();

// Handle promise's fulfilled/rejected states
sendPromise.then(
  function(data) {
    console.log(data.MessageId);
  }).catch(
    function(err) {
    console.error(err, err.stack);
  });
