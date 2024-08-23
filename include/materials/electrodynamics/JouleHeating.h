// Copyright 2023, UChicago Argonne, LLC All Rights Reserved
// License: L-GPL 3.0
#pragma once

#include "Material.h"

class JouleHeating : public Material
{
public:
  static InputParameters validParams();

  JouleHeating(const InputParameters & parameters);

  virtual void computeQpProperties() override;

protected:
  /// The joule heating power per unit volume
  ADMaterialProperty<Real> & _q;

  /// The gradient of the electrical potential
  const ADVariableGradient & _grad_Phi;

  /// The electrical conductivity
  const ADMaterialProperty<Real> & _sigma;
};
