const sinon = require('sinon');
const assert = require('assert');
const ExpiringTokenNotificationJob = require('./ExpiringTokenNotificationJob.js');
const TokenRepository = require('../TokenRepository/TokenRepository.js');
const EmailClient = require('../EmailClient/EmailClient');

describe('ExpiringTokenNotificationJob', () => {

  describe('#run', () => {
    it('gets expiring tokens', () => {
      const tokenRepositoryMock =  sinon.createStubInstance(TokenRepository);
      const emailClientMock =  sinon.createStubInstance(EmailClient);
      tokenRepositoryMock.getExpiringTokens.resolves([{name:"test@test.com", date_trunc: new Date("2021-02-18 11:39:10")}]);

      const expiringNotificationJob = new ExpiringTokenNotificationJob(tokenRepositoryMock, emailClientMock);

      return expiringNotificationJob.run()
      .then(() => {
        sinon.assert.calledOnce(tokenRepositoryMock.getExpiringTokens);
      });
    });

    it('sends an email for each expiring token', () => {
      const tokenRepositoryMock =  sinon.createStubInstance(TokenRepository);
      const emailClientMock =  sinon.createStubInstance(EmailClient);

      tokenRepositoryMock.getExpiringTokens.resolves([{name:"test@test.com", date_trunc: new Date("2021-02-18 11:39:10")}, {name:"test2@test.com", date_trunc: new Date("2021-02-18 11:39:10")}]);
      emailClientMock.sendEmail.resolves();

      const expiringNotificationJob = new ExpiringTokenNotificationJob(tokenRepositoryMock, emailClientMock);

      return expiringNotificationJob.run()
      .then(() => {
        sinon.assert.calledTwice(emailClientMock.sendEmail);
      })
    });

  });

});
