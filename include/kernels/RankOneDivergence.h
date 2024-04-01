// Copyright 2023, UChicago Argonne, LLC All Rights Reserved
// License: L-GPL 3.0
#pragma once

#include "ADKernel.h"

class RankOneDivergence : public ADKernel
{
public:
  static InputParameters validParams();

  RankOneDivergence(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  /// The vector
  const ADMaterialProperty<RealVectorValue> & _vector;

  /// The multiplication factor
  const ADMaterialProperty<Real> & _factor;
};
