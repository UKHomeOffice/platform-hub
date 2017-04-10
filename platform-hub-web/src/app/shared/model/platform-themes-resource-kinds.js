export const PlatformThemesResourceKinds = function () {
  'ngInject';

  const model = {};

  model.all = [
    {name: 'Internal route', kind: 'internal_route'},
    {name: 'External link', kind: 'external_link'},
    {name: 'Support request form', kind: 'support_request'},
    {name: 'Plain text', kind: 'plain_text'}
  ];

  return model;
};
