const sinon = require('sinon');
const assert = require('assert');
const NonExpiringTokenNotificationJob = require('./NonExpiringTokenNotificationJob.js');
const TokenRepository = require('../TokenRepository/TokenRepository.js');
const EmailClient = require('../EmailClient/EmailClient');

describe('NonExpiringTokenNotificationJob', () => {

  describe('#run', () => {
    it('gets non-expiring tokens', () => {
      const tokenRepositoryMock =  sinon.createStubInstance(TokenRepository);
      const emailClientMock =  sinon.createStubInstance(EmailClient);
      tokenRepositoryMock.getNonExpiringTokens.resolves([{name:"test@test.com", kind: 'user', uid:"12a3bc45-1234-1234-abc1-1234a5b67c89"}]);

      const nonExpiringNotificationJob = new NonExpiringTokenNotificationJob(tokenRepositoryMock, emailClientMock);

      return nonExpiringNotificationJob.run()
      .then(() => {
        sinon.assert.calledOnce(tokenRepositoryMock.getNonExpiringTokens);
      });
    });

    it('sends an email for each expiring token', () => {
      const tokenRepositoryMock =  sinon.createStubInstance(TokenRepository);
      const emailClientMock =  sinon.createStubInstance(EmailClient);

      tokenRepositoryMock.getNonExpiringTokens.resolves([{name:"test@test.com", kind: 'robot', uid:"12a3bc45-1234-1234-abc1-1234a5b67c89"}, {name:"test2@test.com", kind: 'user', uid:"12a3bc45-1234-1234-abc1-1234a5b67c89"}]);
      emailClientMock.sendEmail.resolves();

      const nonExpiringNotificationJob = new NonExpiringTokenNotificationJob(tokenRepositoryMock, emailClientMock);

      return nonExpiringNotificationJob.run()
      .then(() => {
        sinon.assert.calledTwice(emailClientMock.sendEmail);
      })
    });

  });

});
