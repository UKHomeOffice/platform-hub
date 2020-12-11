class ExpiringTokenNotificationJob {
  constructor(tokenRepository, userEmail, emailClient){
    this.emailClient = emailClient
    this.userEmail = userEmail
    this.tokenRepository = tokenRepository
  };

  run(){
    return this.tokenRepository.getExpiringTokens()
    .then((expiringTokens) => {
      const subject = "Reminder: Expiring Token";
      const getBody = (kind, uid, date) => `To Platform User <br><br> Your have a ${kind} token with the id <strong>${uid}</strong> that is due to expire on ${date},
      please go to the ACP Hub to regenerate your token. <br><br>Thanks <br>ACP Team`

      return expiringTokens.map(expiringToken => {
        const body = getBody(expiringToken.kind, expiringToken.uid, expiringToken.date_trunc.toDateString());
        const name = expiringToken.name;
        
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


module.exports = ExpiringTokenNotificationJob;
