import angular from 'angular';
import 'angular-mocks';
import {UtilModule} from './util.module';
import sinon from 'sinon';
import chai from 'chai';
import 'chai/register-should';
import sinonChai from 'sinon-chai';
chai.use(sinonChai);

describe('logger', () => {
  let service = null;
  let mockToastr = null;
  let mockLog = null;

  beforeEach(() => {
    const moduleName = `${UtilModule}.loggerService.spec`;
    angular.module(moduleName, ['app']);
    angular.mock.module(moduleName);
  });

  beforeEach(angular.mock.inject(logger => {
    service = logger;
  }));

  beforeEach(angular.mock.inject($log => {
    $log.debug = sinon.stub();
    $log.error = sinon.stub();
    $log.info = sinon.stub();
    $log.warn = sinon.stub();
    mockLog = $log;
  }));

  beforeEach(angular.mock.inject(toastr => {
    toastr.error = sinon.stub();
    toastr.info = sinon.stub();
    toastr.success = sinon.stub();
    toastr.warning = sinon.stub();
    mockToastr = toastr;
  }));

  describe('calling success function', () => {
    it('should call $log.info and toastr.success exactly once with correct message', () => {
      service.success('[SUCCESS] Test Message');

      mockLog.debug.should.have.callCount(0);
      mockLog.error.should.have.callCount(0);
      mockLog.info.should.have.callCount(1);
      mockLog.warn.should.have.callCount(0);
      mockToastr.error.should.have.callCount(0);
      mockToastr.info.should.have.callCount(0);
      mockToastr.success.should.have.callCount(1);
      mockToastr.warning.should.have.callCount(0);
      mockLog.info.should.have.been.calledWith('[SUCCESS] Test Message');
      mockToastr.success.should.have.been.calledWith('[SUCCESS] Test Message');
    });
  });

  describe('calling info function', () => {
    it('should call $log.info and toastr.info exactly once with correct message', () => {
      service.info('[INFO] Test Message');

      mockLog.debug.should.have.callCount(0);
      mockLog.error.should.have.callCount(0);
      mockLog.info.should.have.callCount(1);
      mockLog.warn.should.have.callCount(0);
      mockToastr.error.should.have.callCount(0);
      mockToastr.info.should.have.callCount(1);
      mockToastr.success.should.have.callCount(0);
      mockToastr.warning.should.have.callCount(0);
      mockLog.info.should.have.been.calledWith('[INFO] Test Message');
      mockToastr.info.should.have.been.calledWith('[INFO] Test Message');
    });
  });

  describe('calling error function', () => {
    it('should call $log.error and toastr.error exactly once with correct message', () => {
      var dummyObj = sinon.stub();
      service.error('[ERROR] This is an error:' + dummyObj);

      mockLog.debug.should.have.callCount(0);
      mockLog.error.should.have.callCount(1);
      mockLog.info.should.have.callCount(0);
      mockLog.warn.should.have.callCount(0);
      mockToastr.error.should.have.callCount(1);
      mockToastr.info.should.have.callCount(0);
      mockToastr.success.should.have.callCount(0);
      mockToastr.warning.should.have.callCount(0);
      mockLog.error.should.have.been.calledWith('[ERROR] This is an error:' + dummyObj);
      mockToastr.error.should.have.been.calledWith('[ERROR] This is an error:' + dummyObj);
    });
  });

  describe('calling warning function', () => {
    it('should call $log.warn and toastr.warning exactly once with correct message', () => {
      service.warning('[WARN] Test Message');

      mockLog.debug.should.have.callCount(0);
      mockLog.error.should.have.callCount(0);
      mockLog.info.should.have.callCount(0);
      mockLog.warn.should.have.callCount(1);
      mockToastr.error.should.have.callCount(0);
      mockToastr.info.should.have.callCount(0);
      mockToastr.success.should.have.callCount(0);
      mockToastr.warning.should.have.callCount(1);
      mockLog.warn.should.have.been.calledWith('[WARN] Test Message');
      mockToastr.warning.should.have.been.calledWith('[WARN] Test Message');
    });
  });

  describe('calling debug function', () => {
    it('should call $log.debug exactly once with correct message', () => {
      service.debug('[DEBUG] Test Message');

      mockLog.debug.should.have.callCount(1);
      mockLog.error.should.have.callCount(0);
      mockLog.info.should.have.callCount(0);
      mockLog.warn.should.have.callCount(0);
      mockToastr.error.should.have.callCount(0);
      mockToastr.info.should.have.callCount(0);
      mockToastr.success.should.have.callCount(0);
      mockToastr.warning.should.have.callCount(0);
      mockLog.debug.should.have.been.calledWith('[DEBUG] Test Message');
    });

    it('should call $log.debug exactly once with object in message', () => {
      var dummyObj = sinon.stub();
      service.debug(dummyObj);

      mockLog.debug.should.have.callCount(1);
      mockLog.error.should.have.callCount(0);
      mockLog.info.should.have.callCount(0);
      mockLog.warn.should.have.callCount(0);
      mockToastr.error.should.have.callCount(0);
      mockToastr.info.should.have.callCount(0);
      mockToastr.success.should.have.callCount(0);
      mockToastr.warning.should.have.callCount(0);
      mockLog.debug.should.have.been.calledWith(dummyObj);
    });
  });

  describe('calling multiple functions', () => {
    it('should call the respective $log and toastr functions correctly with the right messages', () => {
      var dummyObj = sinon.stub();
      service.success('[SUCCESS] Test Message');
      service.debug('[DEBUG] Buggy Obj:' + dummyObj);
      service.info('[INFO] Another Message');
      service.info('Bob');

      mockLog.debug.should.have.callCount(1);
      mockLog.error.should.have.callCount(0);
      mockLog.info.should.have.callCount(3);
      mockLog.warn.should.have.callCount(0);
      mockToastr.error.should.have.callCount(0);
      mockToastr.info.should.have.callCount(2);
      mockToastr.success.should.have.callCount(1);
      mockToastr.warning.should.have.callCount(0);
      mockLog.debug.getCall(0).should.have.been.calledWith('[DEBUG] Buggy Obj:' + dummyObj);
      mockLog.info.getCall(0).should.have.been.calledWith('[SUCCESS] Test Message');
      mockLog.info.getCall(1).should.have.been.calledWith('[INFO] Another Message');
      mockLog.info.getCall(2).should.have.been.calledWith('Bob');
      mockToastr.info.getCall(0).should.have.been.calledWith('[INFO] Another Message');
      mockToastr.info.getCall(1).should.have.been.calledWith('Bob');
      mockToastr.success.getCall(0).should.have.been.calledWith('[SUCCESS] Test Message');
    });
  });
});
