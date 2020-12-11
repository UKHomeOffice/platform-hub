var AWS = require('aws-sdk');

class EmailClient {
  constructor() {
    AWS.config.update({region: 'eu-west-1', accessKeyId: process.env.SES_ACCESS_KEY_ID,
    secretAccessKey: process.env.SES_SECRET_ACCESS_KEY});
    this.awsSes = new AWS.SES({apiVersion: '2010-12-01'});
  }

  sendEmail(recipient, body, subject){
    var params = {
      Destination: { /* required */
        ToAddresses: [ recipient ]
      },
      Message: { /* required */
        Body: { /* required */
          Html: {
            Charset: "UTF-8",
            Data: body
          },
          Text: {
            Charset: "UTF-8",
            Data: body
          }
        },
        Subject: {
          Charset: 'UTF-8',
          Data: subject
        }
      },
      Source: process.env.SES_MAIL_FROM_ADDRESS /* required */
    };
    return this.awsSes.sendEmail(params).promise()
    .catch(console.error)
  }

};

module.exports =  EmailClient;
