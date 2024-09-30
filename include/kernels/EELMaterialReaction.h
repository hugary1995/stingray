// Copyright 2023, UChicago Argonne, LLC All Rights Reserved
// License: L-GPL 3.0
#pragma once

#include "ADKernelValue.h"

class EELMaterialReaction : public ADKernelValue
{
public:
  static InputParameters validParams();

  EELMaterialReaction(const InputParameters & parameters);

protected:
  virtual ADReal precomputeQpResidual() override;

  const ADMaterialProperty<Real> & _prop;

  const Real _coef;

  const ADVariableValue & _v;
};
