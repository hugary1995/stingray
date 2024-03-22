// Copyright 2023, UChicago Argonne, LLC All Rights Reserved
// License: L-GPL 3.0

#pragma once

#include "ElementIntegralPostprocessor.h"

class EnthalpyRate : public ElementIntegralPostprocessor
{
public:
  static InputParameters validParams();

  EnthalpyRate(const InputParameters & parameters);

protected:
  virtual Real computeQpIntegral() override;

  const ADMaterialProperty<Real> & _rho;

  const ADMaterialProperty<Real> & _cp;

  const ADVariableValue & _T_dot;
};
