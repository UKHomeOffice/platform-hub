const _ = require('lodash');

class ExpiredTokenNotificationJob {
  constructor(tokenRepository, emailClient){
    this.emailClient = emailClient
    this.tokenRepository = tokenRepository
  };

   run(){
    return this.tokenRepository.getExpiredTokens()
    .then((expiredTokens) => {
      const subject = "Reminder: Expiring Token";
      const getBody = (date) => `To Platform User <br><br> Your have a token that is due to expire on ${date},
      please go to the ACP Hub to regenerate your token. <br><br>Thanks <br>ACP Team`

      return expiredTokens.map(expiredToken => {
        const recipient = expiredToken.name;
        const body = getBody(expiredToken.date_trunc.toDateString());

        return this.emailClient.sendEmail(recipient, body, subject);
      });
    })
  }
}


module.exports = ExpiredTokenNotificationJob;
