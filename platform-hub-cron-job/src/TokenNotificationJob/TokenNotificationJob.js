class TokenNotificationJob {
  constructor(notificationsService){
    
    this.notificationsService = notificationsService
  };

  run(){
    return Promise.all([this.notificationsService.sendExpiringTokenNotifications(), this.notificationsService.sendExpiredTokenNotifications()])
  }

}


module.exports = TokenNotificationJob;
