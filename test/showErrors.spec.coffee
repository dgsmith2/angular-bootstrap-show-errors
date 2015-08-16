describe 'showErrors', ->
  $compile = undefined
  $scope = undefined
  $timeout = undefined
  validName = 'Paul'
  invalidName = 'Pa'

  beforeEach module('res.showErrors')
  beforeEach inject((_$compile_, _$rootScope_, _$timeout_) ->
    $compile = _$compile_
    $scope = _$rootScope_
    $timeout = _$timeout_
  )

  compileEl = ->
    el = $compile(
        '<form name="userForm">
          <div id="first-name-group" class="form-group" res-show-errors>
            <input type="text" name="firstName" ng-model="firstName" ng-minlength="3" class="form-control" />
          </div>
          <div id="last-name-group" class="form-group" res-show-errors="{ showSuccess: true }">
            <input type="text" name="lastName" ng-model="lastName" ng-minlength="3" class="form-control" />
          </div>
        </form>'
      )($scope)
    angular.element(document.body).append el
    $scope.$digest()
    el

  describe 'directive does not contain an input element with a form-control class and name attribute', ->
    it 'throws an exception', ->
      expect( ->
        $compile('<form name="userFor"><div class="form-group" res-show-errors><input type="text" name="firstName"></input></div></form>')($scope)
      ).toThrow "show-errors element has no child input elements with a 'name' attribute and a 'form-control' class"

  it 'directive can find \'form-control\' in nested divs', ->
    expect( ->
      $compile('<form name="userFor"><div class="form-group" res-show-errors><div class="wrapper-container"><input type="text" class="form-control" name="firstName"></input></div></div></form>')($scope)
    ).not.toThrow

  it "throws an exception if the element doesn't have the form-group or input-group class", ->
    expect( ->
      $compile('<div res-show-errors></div>')($scope)
    ).toThrow "show-errors element does not have the 'form-group' or 'input-group' class"

  it "doesn't throw an exception if the element has the input-group class", ->
    expect( ->
      $compile('<form name="userForm"><div class="input-group" res-show-errors><input class="form-control" type="text" name="firstName"></input></div></form>')($scope)
    ).not.toThrow()

  it "doesn't throw an exception if the element doesn't have the form-group class but uses the skipFormGroupCheck option", ->
    expect( ->
      $compile('<form name="userForm"><div res-show-errors="{ skipFormGroupCheck: true }"><input class="form-control" type="text" name="firstName"></input></div></form>')($scope)
    ).not.toThrow()

  it "throws an exception if the element isn't in a form tag", ->
    expect( ->
      $compile('<div class="form-group" res-show-errors><input type="text" name="firstName"></input></div>')($scope)
    ).toThrow()

  describe '$pristine && $invalid', ->
    it 'has-error is absent', ->
      el = compileEl()
      expectFormGroupHasErrorClass(el).toBe false

  describe '$dirty && $invalid && blurred', ->
    it 'has-error is present', ->
      el = compileEl()
      $scope.userForm.firstName.$setViewValue invalidName
      angular.element(firstNameEl(el)).triggerHandler 'blur'
      expectFormGroupHasErrorClass(el).toBe true

  describe '$dirty && $invalid && not blurred', ->
    it 'has-error is absent', ->
      el = compileEl()
      $scope.userForm.firstName.$setViewValue invalidName
      angular.element(firstNameEl(el)).triggerHandler 'keydown'
      expectFormGroupHasErrorClass(el).toBe false

  describe '$valid && blurred', ->
    it 'has-error is absent', ->
      el = compileEl()
      $scope.userForm.firstName.$setViewValue validName
      angular.element(firstNameEl(el)).triggerHandler 'blur'
      expectFormGroupHasErrorClass(el).toBe false

  describe '$valid && blurred then becomes $invalid before blurred', ->
    it 'has-error is present', ->
      el = compileEl()
      $scope.userForm.firstName.$setViewValue validName
      angular.element(firstNameEl(el)).triggerHandler 'blur'
      $scope.$apply ->
        $scope.userForm.firstName.$setViewValue invalidName
      expectFormGroupHasErrorClass(el).toBe true

  describe '$valid && blurred then becomes $valid before blurred', ->
    it 'has-error is absent', ->
      el = compileEl()
      $scope.userForm.firstName.$setViewValue validName
      angular.element(firstNameEl(el)).triggerHandler 'blur'
      $scope.$apply ->
        $scope.userForm.firstName.$setViewValue invalidName
      $scope.$apply ->
        $scope.userForm.firstName.$setViewValue validName
      expectFormGroupHasErrorClass(el).toBe false

  describe '$valid && blurred then becomes $invalid after blurred', ->
    it 'has-error is present', ->
      el = compileEl()
      $scope.userForm.firstName.$setViewValue validName
      angular.element(firstNameEl(el)).triggerHandler 'blur'
      $scope.userForm.firstName.$setViewValue invalidName
      angular.element(firstNameEl(el)).triggerHandler 'blur'
      expectFormGroupHasErrorClass(el).toBe true

  describe '$valid && blurred then $invalid after blurred then $valid after blurred', ->
    it 'has-error is absent', ->
      el = compileEl()
      $scope.userForm.firstName.$setViewValue validName
      angular.element(firstNameEl(el)).triggerHandler 'blur'
      $scope.userForm.firstName.$setViewValue invalidName
      angular.element(firstNameEl(el)).triggerHandler 'blur'
      $scope.userForm.firstName.$setViewValue validName
      angular.element(firstNameEl(el)).triggerHandler 'blur'
      expectFormGroupHasErrorClass(el).toBe false

  describe '$valid && other input is $invalid && blurred', ->
    it 'has-error is absent', ->
      el = compileEl()
      $scope.userForm.firstName.$setViewValue validName
      $scope.userForm.lastName.$setViewValue invalidName
      angular.element(firstNameEl(el)).triggerHandler 'blur'
      expectFormGroupHasErrorClass(el).toBe false

  describe '$invalid && showErrorsCheckValidity is set before blurred', ->
    it 'has-error is present', ->
      el = compileEl()
      $scope.userForm.firstName.$setViewValue invalidName
      $scope.$broadcast 'show-errors-check-validity'
      expectFormGroupHasErrorClass(el).toBe true

  describe 'showErrorsCheckValidity is called twice', ->
    it 'correctly applies the has-error class', ->
      el = compileEl()
      $scope.userForm.firstName.$setViewValue invalidName
      $scope.$broadcast 'show-errors-check-validity'
      $scope.userForm.firstName.$setViewValue validName
      angular.element(firstNameEl(el)).triggerHandler 'blur'
      $scope.userForm.firstName.$setViewValue invalidName
      $scope.$apply ->
        $scope.showErrorsCheckValidity = true
      expectFormGroupHasErrorClass(el).toBe true

  describe 'showErrorsReset', ->
    it 'removes has-error', ->
      el = compileEl()
      $scope.userForm.firstName.$setViewValue invalidName
      angular.element(firstNameEl(el)).triggerHandler 'blur'
      $scope.$broadcast 'show-errors-reset'
      $timeout.flush()
      expectFormGroupHasErrorClass(el).toBe false

  describe 'showErrorsReset then invalid without blurred', ->
    it 'has-error is absent', ->
      el = compileEl()
      $scope.userForm.firstName.$setViewValue validName
      angular.element(firstNameEl(el)).triggerHandler 'blur'
      $scope.$broadcast 'show-errors-reset'
      $timeout.flush()
      $scope.$apply ->
        $scope.userForm.firstName.$setViewValue invalidName
      expectFormGroupHasErrorClass(el).toBe false

  describe 'call showErrorsReset multiple times', ->
    it 'removes has-error', ->
      el = compileEl()
      $scope.userForm.firstName.$setViewValue invalidName
      angular.element(firstNameEl(el)).triggerHandler 'blur'
      $scope.$broadcast 'show-errors-reset'
      $timeout.flush()
      angular.element(firstNameEl(el)).triggerHandler 'blur'
      $scope.$broadcast 'show-errors-reset'
      $timeout.flush()
      expectFormGroupHasErrorClass(el).toBe false

  describe 'form input has dynamic name', ->
    it 'should get name correctly', ->
      $scope.uniqueId = 0
      el = $compile(
          '<form name="userForm">
            <div id="first-name-group" class="form-group" res-show-errors>
              <input type="text" name="firstName_{{uniqueId}}" ng-model="firstName" ng-minlength="3" class="form-control" />
            </div>
          </form>'
        )($scope)
      $scope.uniqueId = 5
      # $scope.$digest()
      angular.element(find(el, '[name=firstName_5]')).triggerHandler 'blur'
      formGroup = el[0].querySelector '[id=first-name-group]'
      expect angular.element(formGroup).hasClass('show-errors')

  describe '{showSuccess: true} option', ->
    describe '$pristine && $valid', ->
      it 'has-success is absent', ->
        el = compileEl()
        expectLastNameFormGroupHasSuccessClass(el).toBe false

    describe '$dirty && $valid && blurred', ->
      it 'has-success is present', ->
        el = compileEl()
        $scope.userForm.lastName.$setViewValue validName
        angular.element(lastNameEl(el)).triggerHandler 'blur'
        $scope.$digest()
        expectLastNameFormGroupHasSuccessClass(el).toBe true

    describe '$dirty && $invalid && blurred', ->
      it 'has-success is present', ->
        el = compileEl()
        $scope.userForm.lastName.$setViewValue invalidName
        angular.element(lastNameEl(el)).triggerHandler 'blur'
        $scope.$digest()
        expectLastNameFormGroupHasSuccessClass(el).toBe false

    describe '$invalid && blurred then becomes $valid before blurred', ->
      it 'has-success is present', ->
        el = compileEl()
        $scope.userForm.lastName.$setViewValue invalidName
        angular.element(lastNameEl(el)).triggerHandler 'blur'
        $scope.$apply ->
          $scope.userForm.lastName.$setViewValue invalidName
        $scope.$apply ->
          $scope.userForm.lastName.$setViewValue validName
        expectLastNameFormGroupHasSuccessClass(el).toBe true

    describe '$valid && showErrorsCheckValidity is set before blurred', ->
      it 'has-success is present', ->
        el = compileEl()
        $scope.userForm.lastName.$setViewValue validName
        $scope.$broadcast 'show-errors-check-validity'
        expectLastNameFormGroupHasSuccessClass(el).toBe true

    describe 'showErrorsReset', ->
      it 'removes has-success', ->
        el = compileEl()
        $scope.userForm.lastName.$setViewValue validName
        angular.element(lastNameEl(el)).triggerHandler 'blur'
        $scope.$broadcast 'show-errors-reset'
        $timeout.flush()
        expectLastNameFormGroupHasSuccessClass(el).toBe false

describe 'showErrorsConfig with alternate form control class', ->
  $compile = undefined
  $scope = undefined
  $timeout = undefined
  validName = 'Paul'
  invalidName = 'Pa'

  beforeEach ->
    testModule = angular.module 'testModule', []
    testModule.config (resShowErrorsConfigProvider) ->
      resShowErrorsConfigProvider.formControlClass 'prj-form-control'
      resShowErrorsConfigProvider.skipFormGroupCheck true

    module 'res.showErrors', 'testModule'

    inject((_$compile_, _$rootScope_, _$timeout_) ->
      $compile = _$compile_
      $scope = _$rootScope_
      $timeout = _$timeout_
    )

  describe 'when resShowErrorsConfig.formControlClass is set', ->
    describe 'and no options are given', ->
      it 'should not throw error', ->
        expect( ->
          $compile('<form name="userForm"><div class="input-group" res-show-errors><input class="prj-form-control" type="text" name="firstName"></input></div></form>')($scope)
        ).not.toThrow()

      it 'should throw error if class is not found', ->
        expect( ->
          $compile('<form name="userForm"><div class="input-group" res-show-errors><input class="form-control" type="text" name="firstName"></input></div></form>')($scope)
        ).toThrow "show-errors element has no child input elements with a 'name' attribute and a 'prj-form-control' class"

    describe 'and options are given', ->
      it 'should throw exceptions if override dosent match class names', ->
        expect( ->
          $compile('<form name="userForm"><div class="input-group" res-show-errors="{formControlClass: \'blah-blah\'}"><input class="form-control" type="text" name="firstName"></input></div></form>')($scope)
        ).toThrow "show-errors element has no child input elements with a 'name' attribute and a 'blah-blah' class"

      it 'should find the name if given override', ->
        expect( ->
          $compile('<form name="userForm"><div class="input-group" res-show-errors="{formControlClass: \'blah-blah\'}"><input class="blah-blah" type="text" name="firstName"></input></div></form>')($scope)
        ).not.toThrow()
  describe 'when resShowErrorsConfig.skipFormGroupCheck is set', ->
    describe 'and no options are given', ->
      it 'should not throw an error', ->
          expect( ->
            $compile('<form name="userForm"><div res-show-errors><input class="prj-form-control" type="text" name="firstName"></input></div></form>')($scope)
          ).not.toThrow()
    describe 'and options are given', ->
      # TODO: local options don't override the skip check to false because the compile time check of this property only checks that it exists, not weither it's true or false.
      xit 'should throw an error', ->
          expect( ->
            $compile('<form name="userForm"><div res-show-errors="{skipFormGroupCheck: \'false\'}"><input class="prj-form-control" type="text" name="firstName"></input></div></form>')($scope)
          ).toThrow()

describe 'showErrorsConfig', ->
  $compile = undefined
  $scope = undefined
  $timeout = undefined
  validName = 'Paul'
  invalidName = 'Pa'

  beforeEach ->
    testModule = angular.module 'testModule', []
    testModule.config (resShowErrorsConfigProvider) ->
      resShowErrorsConfigProvider.showSuccess true
      resShowErrorsConfigProvider.trigger 'keypress'
      resShowErrorsConfigProvider.errorClass 'res-val-error'

    module 'res.showErrors', 'testModule'

    inject((_$compile_, _$rootScope_, _$timeout_) ->
      $compile = _$compile_
      $scope = _$rootScope_
      $timeout = _$timeout_
    )

  compileEl = ->
    el = $compile(
        '<form name="userForm">
          <div id="first-name-group" class="form-group" res-show-errors="{showSuccess: false, trigger: \'blur\'}">
            <input type="text" name="firstName" ng-model="firstName" ng-minlength="3" class="form-control" />
          </div>
          <div id="last-name-group" class="form-group" res-show-errors>
            <input type="text" name="lastName" ng-model="lastName" ng-minlength="3" class="form-control" />
          </div>
        </form>'
      )($scope)
    angular.element(document.body).append el
    $scope.$digest()
    el

  describe 'when showErrorsConfig.showSuccess is true', ->
    describe 'and no options given', ->
      it 'show-success class is applied', ->
        el = compileEl()
        $scope.userForm.lastName.$setViewValue validName
        angular.element(lastNameEl(el)).triggerHandler 'keypress'
        $scope.$digest()
        expectLastNameFormGroupHasSuccessClass(el).toBe true

  describe 'when showErrorsConfig.errorClass is "res-val-error"', ->
    describe 'and no options given', ->
      it '"res-val-error" class is applied', ->
        el = compileEl()
        $scope.userForm.lastName.$setViewValue invalidName
        angular.element(lastNameEl(el)).triggerHandler 'keypress'
        $scope.$digest()
        expectLastNameFormGroupHasErrorClass(el, 'res-val-error').toBe true

  describe 'when showErrorsConfig.showSuccess is true', ->
    describe 'but options.showSuccess is false', ->
      it 'show-success class is not applied', ->
        el = compileEl()
        $scope.userForm.firstName.$setViewValue validName
        angular.element(firstNameEl(el)).triggerHandler 'blur'
        $scope.$digest()
        expectFirstNameFormGroupHasSuccessClass(el).toBe false

  describe 'when showErrorsConfig.trigger is "keypress"', ->
    describe 'and no options given', ->
      it 'validates the value on the first keypress', ->
        el = compileEl()
        $scope.userForm.lastName.$setViewValue invalidName
        angular.element(lastNameEl(el)).triggerHandler 'keypress'
        $scope.$digest()
        expectLastNameFormGroupHasErrorClass(el, 'res-val-error').toBe true

    describe 'but options.trigger is "blur"', ->
      it 'does not validate the value on keypress', ->
        el = compileEl()
        $scope.userForm.firstName.$setViewValue invalidName
        angular.element(firstNameEl(el)).triggerHandler 'keypress'
        $scope.$digest()
        expectFirstNameFormGroupHasErrorClass(el, 'res-val-error').toBe false

find = (el, selector) ->
  el[0].querySelector selector

firstNameEl = (el) ->
  find el, '[name=firstName]'

lastNameEl = (el) ->
  find el, '[name=lastName]'

expectFormGroupHasErrorClass = (el, errorClass) ->
  _errorClass = 'has-error'
  if errorClass?
    _errorClass = errorClass
  formGroup = el[0].querySelector '[id=first-name-group]'
  expect angular.element(formGroup).hasClass(_errorClass)

expectFirstNameFormGroupHasSuccessClass = (el) ->
  formGroup = el[0].querySelector '[id=first-name-group]'
  expect angular.element(formGroup).hasClass('has-success')

expectLastNameFormGroupHasSuccessClass = (el) ->
  formGroup = el[0].querySelector '[id=last-name-group]'
  expect angular.element(formGroup).hasClass('has-success')

expectFirstNameFormGroupHasErrorClass = (el, errorClass) ->
  _errorClass = 'has-error'
  if errorClass?
    _errorClass = errorClass
  formGroup = el[0].querySelector '[id=first-name-group]'
  expect angular.element(formGroup).hasClass(_errorClass)

expectLastNameFormGroupHasErrorClass = (el, errorClass) ->
  _errorClass = 'has-error'
  if errorClass?
    _errorClass = errorClass
  formGroup = el[0].querySelector '[id=last-name-group]'
  expect angular.element(formGroup).hasClass(_errorClass)
