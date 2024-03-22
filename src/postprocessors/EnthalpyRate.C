// Copyright 2023, UChicago Argonne, LLC All Rights Reserved
// License: L-GPL 3.0

#include "EnthalpyRate.h"

#include "metaphysicl/raw_type.h"

registerMooseObject("EelApp", EnthalpyRate);

InputParameters
EnthalpyRate::validParams()
{
  InputParameters params = ElementIntegralPostprocessor::validParams();
  params.addClassDescription("Compute the enthalpy change using trapezoidal rule");
  params.addRequiredParam<MaterialPropertyName>("density", "density");
  params.addRequiredParam<MaterialPropertyName>("specific_heat", "specific heat");
  params.addRequiredCoupledVar("temperature", "Temperature variable");
  return params;
}

EnthalpyRate::EnthalpyRate(const InputParameters & parameters)
  : ElementIntegralPostprocessor(parameters),
    _rho(getADMaterialProperty<Real>("density")),
    _cp(getADMaterialProperty<Real>("specific_heat")),
    _T_dot(adCoupledDot("temperature"))
{
}

Real
EnthalpyRate::computeQpIntegral()
{
  return MetaPhysicL::raw_value(_rho[_qp] * _cp[_qp] * _T_dot[_qp]);
}
