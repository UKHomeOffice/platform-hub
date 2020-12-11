const _ = require('lodash');

class NonExpiringTokenNotificationJob {
  constructor(tokenRepository, userEmail, emailClient){
    this.emailClient = emailClient
    this.userEmail = userEmail
    this.tokenRepository = tokenRepository
  };
  
  run(){
    return this.tokenRepository.getNonExpiringTokens()
    .then((nonExpiringTokens) => {
      const subject = "Long-Lived Kubernetes Token ";
      const getBody = (kind, uid) => `To Platform User <br><br> Your have a long-lived ${kind} token with the id <strong>${uid}</strong>. <br> Long-lived tokens are not recommended as they do not expire. <br><br> We are asking our users to check that they need these tokens and to rotate their tokens.
      To rotate a token at least every 30 days, please go the the ACP Hub to regenerate the token. <br><br>Thanks <br>ACP Team`
      
      return nonExpiringTokens.map(nonExpiringToken => {
        const body = getBody(nonExpiringToken.kind, nonExpiringToken.uid);
        const name = nonExpiringToken.name;
        
        return this.userEmail.getEmail(name).then((userEmails) => {
          return userEmails.map(userEmail => {
            const recipient = userEmail.name
            
            return this.emailClient.sendEmail(recipient, body, subject);
          })
        })
        .catch(err => console.error(err));
      });
    })
    .catch(console.error)
  }
}


module.exports = NonExpiringTokenNotificationJob;
