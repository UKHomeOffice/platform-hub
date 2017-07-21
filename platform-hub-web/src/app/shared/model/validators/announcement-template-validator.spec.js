/* eslint camelcase: 0 */

import angular from 'angular';

import 'angular-mocks';

import {ModelModule} from '../model.module';

describe('announcementTemplateValidator', () => {
  let validator = null;

  beforeEach(() => {
    const moduleName = `${ModelModule}.announcementTemplateValidator.spec`;
    angular.module(moduleName, ['app']);
    angular.mock.module(moduleName);
  });

  beforeEach(angular.mock.inject(announcementTemplateValidator => {
    validator = announcementTemplateValidator;
  }));

  describe('.validate', () => {
    describe('given a template with valid fields and template definitions', () => {
      const template = {
        spec: {
          fields: [{id: 'foo'}, {id: 'bar'}, {id: 'baz'}],
          templates: {
            title: 'Hello {{foo}} and {{baz}}',
            on_hub: 'Hello {{foo}} and \n{{baz}}\n',
            email_html: 'Hello {{foo}} and \n{{baz}}\n',
            email_text: 'Hello {{foo}} and \n{{baz}}\n',
            slack: 'Hello {{foo}} and \n{{baz}}\n'
          }
        }
      };

      it('should return no errors', () => {
        expect(validator.validate(template)).toEqual([]);
      });
    });

    describe('given a template with invalid template definitions', () => {
      const template = {
        spec: {
          fields: [{id: 'foo'}, {id: 'bar'}, {id: 'baz'}],
          templates: {
            title: 'Hello {{fooooo}} and {{baz}}',
            on_hub: 'Hello {{foo}} and \n{{baz}}\n',
            email_html: 'Hello {{foo}} and \n{{bar}}\n',
            email_text: 'Hello {{foo}} and \n{{bazzzz}}\n',
            slack: 'Hello {{foo}} and \n{{nothing}}\n and {{nope}}'
          }
        }
      };

      const errors = [
        'title template definition references field(s) that don\'t exist: fooooo',
        'email_text template definition references field(s) that don\'t exist: bazzzz',
        'slack template definition references field(s) that don\'t exist: nothing, nope'
      ];

      it('should return the specified errors', () => {
        expect(validator.validate(template)).toEqual(errors);
      });
    });
  });
});
