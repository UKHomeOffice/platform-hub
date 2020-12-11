const sinon = require('sinon');
const { expect } = require('chai');
const assert = require('assert');
const ExpiredTokenNotificationJob = require('./ExpiredTokenNotificationJob.js');
const TokenRepository = require('../TokenRepository/TokenRepository.js');
const EmailClient = require('../EmailClient/EmailClient');

describe('ExpiredTokenNotificationJob', () => {

  describe('#run', () => {
    it('gets expired tokens', () => {
      const tokenRepositoryMock =  sinon.createStubInstance(TokenRepository);
      const emailClientMock =  sinon.createStubInstance(EmailClient);
      tokenRepositoryMock.getExpiredTokens.resolves([{name:"test@test.com", date_trunc: new Date("2021-02-18 11:39:10")}]);

      const expiredNotificationJob = new ExpiredTokenNotificationJob(tokenRepositoryMock, emailClientMock);

      return expiredNotificationJob.run()
      .then(() => {
        sinon.assert.calledOnce(tokenRepositoryMock.getExpiredTokens);
      });
    });

    it('sends an email for each expired token', () => {
      const tokenRepositoryMock =  sinon.createStubInstance(TokenRepository);
      const emailClientMock =  sinon.createStubInstance(EmailClient);

      tokenRepositoryMock.getExpiredTokens.resolves([{name:"test@test.com", date_trunc: new Date("2021-02-18 11:39:10")}, {name:"test2@test.com", date_trunc: new Date("2021-02-18 11:39:10")}]);
      emailClientMock.sendEmail.resolves();

      const expiredNotificationJob = new ExpiredTokenNotificationJob(tokenRepositoryMock, emailClientMock);

      return expiredNotificationJob.run()
      .then(() => {
        sinon.assert.calledTwice(emailClientMock.sendEmail);
      })
    });

  });

});
