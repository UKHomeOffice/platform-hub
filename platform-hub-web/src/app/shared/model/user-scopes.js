export const UserScopes = function (Me, _) {
  'ngInject';

  const model = {};

  model.all = [
    {name: 'Managerial', value: 'managerial'},
    {name: 'Technical', value: 'technical'}
  ];

  model.isVisibleToCurrentUser = isVisibleToCurrentUser;

  return model;

  function isVisibleToCurrentUser(scope) {
    if (_.isNull(scope) || _.isUndefined(scope) || _.isEmpty(scope)) {
      return true;
    }

    switch (scope.toLowerCase()) {
      case 'managerial':
        return Boolean(Me.data.is_managerial);
      case 'technical':
        return Boolean(Me.data.is_technical);
      default:
        return true;
    }
  }
};
