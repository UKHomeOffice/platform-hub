class NotificationsService {
  constructor(tokenRepository, userEmail, emailClient, s3Client){
    this.tokenRepository = tokenRepository
    this.userEmail = userEmail
    this.emailClient = emailClient
    this.s3Client = s3Client
  }

  sendExpiringTokenNotifications(){
    return this.tokenRepository.getExpiringTokens()
    .then((expiringTokens) => {
      const subject = "Reminder: Expiring Token";
      const getBody = (kind, uid, project, cluster, date) => `To Platform User <br><br> You have a ${kind} token with the following details:
      <br><br>
      <strong>UID: ${uid}</strong><br>
      <strong>Project: ${project}</strong> <br>
      <strong>Cluster: ${cluster}</strong> <br><br>
      that is due to expire on ${date}.
      Please go to the ACP Hub to regenerate your token. <br><br>Thanks <br>ACP Team`

      return expiringTokens.map(expiringToken => {
        const body = getBody(expiringToken.kind, expiringToken.uid, expiringToken.project_name, expiringToken.cluster_name, expiringToken.date_trunc.toDateString());
        const name = expiringToken.name;

        return this.userEmail.getEmail(name).then((userEmails) => {
          return userEmails.map(userEmail => {
            const recipient = userEmail.name

            return this.emailClient.sendEmail(recipient, body, subject);
          })
        })
      });
    })
  }

  sendExpiredTokenNotifications(){
    return this.tokenRepository.getExpiredTokens()
    .then((expiredTokens) => {
      const subject = "Expired Token";
      const getBody = (kind, uid, project, cluster, date) => `To Platform User <br><br> Your ${kind} token with the following details:
      <br><br>
      <strong>UID: ${uid}</strong><br>
      <strong>Project: ${project}</strong> <br>
      <strong>Cluster: ${cluster}</strong> <br><br>
      has expired.
      Please go to the ACP Hub to regenerate your token. <br><br>Thanks <br>ACP Team`
    
      return expiredTokens.map(expiredToken => {
        const body = getBody(expiredToken.kind, expiredToken.uid, expiredToken.project_name, expiredToken.cluster_name, expiredToken.date_trunc.toDateString());
        const name = expiredToken.name;
        const uid = expiredToken.uid;
        const s3_object_key = expiredToken.s3_object_key
    
        return this.userEmail.getEmail(name).then((userEmails) => {
          return userEmails.map(userEmail => {
            const recipient = userEmail.name
    
            return this.emailClient.sendEmail(recipient, body, subject)
            .then(() => {
              return this.s3Client.getAndUpdateFile(uid, s3_object_key)
            })
          })
        })
      });
    })
  }
}

module.exports = NotificationsService;
