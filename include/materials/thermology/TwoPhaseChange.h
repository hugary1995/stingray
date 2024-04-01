// Copyright 2023, UChicago Argonne, LLC All Rights Reserved
// License: L-GPL 3.0
#pragma once

#include "Material.h"

class TwoPhaseChange : public Material
{
public:
  static InputParameters validParams();
  TwoPhaseChange(const InputParameters & parameters);

  enum class PhaseChangeState
  {
    BEFORE,
    AFTER,
    TRANSITION
  };

protected:
  void initQpStatefulProperties() override;
  void computeQpProperties() override;
  void computeQpState();
  void computeQpLatentSpecificHeat();

  ADMaterialProperty<Real> & _phi;
  ADMaterialProperty<PhaseChangeState> & _state;
  const MaterialProperty<PhaseChangeState> & _state_old;

  ADMaterialProperty<Real> & _cpL;
  const ADMaterialProperty<Real> & _L;

  const ADVariableValue & _T;
  const ADMaterialProperty<Real> & _Ts;
  const ADMaterialProperty<Real> & _Te;
};
