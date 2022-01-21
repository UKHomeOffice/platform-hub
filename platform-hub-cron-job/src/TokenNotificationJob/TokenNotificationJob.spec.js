const sinon = require('sinon');
const assert = require('assert');
const ExpiringTokenNotificationJob = require('./ExpiringTokenNotificationJob.js');
const TokenRepository = require('../TokenRepository/TokenRepository.js');
const UserEmail = require('../UserEmail/UserEmail');
const EmailClient = require('../EmailClient/EmailClient');

describe('ExpiringTokenNotificationJob', () => {

  describe('#run', () => {
    it('gets expiring tokens', () => {
      const tokenRepositoryMock =  sinon.createStubInstance(TokenRepository);
      const userEmailMock =  sinon.createStubInstance(UserEmail);
      const emailClientMock =  sinon.createStubInstance(EmailClient);
      
      tokenRepositoryMock.getExpiringTokens.resolves([{name:"foo", kind: 'user', uid:"12a3bc45-1234-1234-abc1-1234a5b67c89", date_trunc: new Date("2021-02-18 11:39:10")}]);
      userEmailMock.getEmail.resolves([{name: "test@test.com"}])
      
      const expiringNotificationJob = new ExpiringTokenNotificationJob(tokenRepositoryMock, userEmailMock, emailClientMock);
    
      return expiringNotificationJob.run()
      .then(() => {
        sinon.assert.calledOnce(tokenRepositoryMock.getExpiringTokens);
      });
    });
    
    it('gets user emails', () => {
      const tokenRepositoryMock =  sinon.createStubInstance(TokenRepository);
      const userEmailMock =  sinon.createStubInstance(UserEmail);
      const emailClientMock =  sinon.createStubInstance(EmailClient);
      
      tokenRepositoryMock.getExpiringTokens.resolves([{name:"foo", kind: 'user', uid:"12a3bc45-1234-1234-abc1-1234a5b67c89", date_trunc: new Date("2021-02-18 11:39:10")}]);
      userEmailMock.getEmail.resolves([{name: "test@test.com"}])
      
      const expiringNotificationJob = new ExpiringTokenNotificationJob(tokenRepositoryMock, userEmailMock, emailClientMock);

      return expiringNotificationJob.run()
      .then(() => {
        sinon.assert.calledOnce(userEmailMock.getEmail);
      });
    });

    it('sends an email for each expiring token', () => {
      const tokenRepositoryMock =  sinon.createStubInstance(TokenRepository);
      const userEmailMock =  sinon.createStubInstance(UserEmail);
      const emailClientMock =  sinon.createStubInstance(EmailClient);
    
      tokenRepositoryMock.getExpiringTokens.resolves([{name:"foo", kind: 'robot', uid:"12a3bc45-1234-1234-abc1-1234a5b67c89", date_trunc: new Date("2021-02-18 11:39:10")}, {name:"foo1", kind: 'user', uid:"12a3bc45-1234-1234-abc1-1234a5b67c89", date_trunc: new Date("2021-02-18 11:39:10")}]);
      userEmailMock.getEmail.resolves([{name:"test@test.com"}]);
      emailClientMock.sendEmail.resolves();
    
      const expiringNotificationJob = new ExpiringTokenNotificationJob(tokenRepositoryMock, userEmailMock, emailClientMock);
    
      return expiringNotificationJob.run()
      .then(() => {
        sinon.assert.calledTwice(emailClientMock.sendEmail);
      })
    });

  });

});
