/* eslint camelcase: 0 */

export const FieldsEditorComponent = {
  bindings: {
    title: '@',
    fieldTypes: '<',
    fields: '=',
    form: '<'
  },
  template: require('./fields-editor.html'),
  controller: FieldsEditorController
};

function FieldsEditorController(_) {
  'ngInject';

  const ctrl = this;

  ctrl.idRegex = '\\w+';

  ctrl.add = add;
  ctrl.remove = remove;
  ctrl.moveDown = moveDown;
  ctrl.moveUp = moveUp;

  function add() {
    if (!ctrl.fields) {
      ctrl.fields = [];
    }
    ctrl.fields.push({
      field_type: ctrl.fieldTypes[0],
      required: true,
      multiple: false
    });
  }

  function remove(ix) {
    if (!_.isEmpty(ctrl.fields)) {
      ctrl.fields.splice(ix, 1);
    }
  }

  function moveDown(ix) {
    const fields = ctrl.fields;
    const field1 = fields[ix];
    const field2 = fields[ix + 1];
    fields.splice(ix, 2, field2, field1);
  }

  function moveUp(ix) {
    const fields = ctrl.fields;
    const field1 = fields[ix - 1];
    const field2 = fields[ix];
    fields.splice(ix - 1, 2, field2, field1);
  }
}
