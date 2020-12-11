const _ = require('lodash');

class ExpiringTokenNotificationJob {
  constructor(tokenRepository, emailClient){
    this.emailClient = emailClient
    this.tokenRepository = tokenRepository
  };

   run(){
    return this.tokenRepository.getExpiringTokens()
    .then((expiringTokens) => {
      const subject = "Reminder: Expiring Token";
      const getBody = (date) => `To Platform User <br><br> Your have a token that is due to expire on ${date},
      please go to the ACP Hub to regenerate your token. <br><br>Thanks <br>ACP Team`

      return expiringTokens.map(expiringToken => {
        const recipient = expiringToken.name;
        const body = getBody(expiringToken.date_trunc.toDateString());

        return this.emailClient.sendEmail(recipient, body, subject);
      });
    })
  }
}


module.exports = ExpiringTokenNotificationJob;
