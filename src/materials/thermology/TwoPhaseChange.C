// Copyright 2023, UChicago Argonne, LLC All Rights Reserved
// License: L-GPL 3.0

#include "TwoPhaseChange.h"
#include "MathUtils.h"

registerMooseObject("EelApp", TwoPhaseChange);

InputParameters
TwoPhaseChange::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "This material models the phase change between solid and liquid, i.e. melting and "
      "freezing, using an effective latent specific heat.");
  params.addRequiredCoupledVar("temperature", "The temperature");
  params.addRequiredParam<MaterialPropertyName>("phase", "Phase of the material");
  params.addRequiredParam<MaterialPropertyName>("starting_temperature",
                                                "Temperature at which the phase change begins");
  params.addRequiredParam<MaterialPropertyName>("ending_temperature",
                                                "Temperature at which the phase change ends");
  params.addRequiredParam<MaterialPropertyName>("latent_heat", "Latent heat");
  params.addRequiredParam<MaterialPropertyName>("latent_specific_heat", "Latent specific heat");
  return params;
}

TwoPhaseChange::TwoPhaseChange(const InputParameters & parameters)
  : Material(parameters),
    _phi(declareADProperty<Real>("phase")),
    _state(declareADPropertyByName<PhaseChangeState>("_phase_change_state")),
    _state_old(getMaterialPropertyOldByName<PhaseChangeState>("_phase_change_state")),
    _cpL(declareADProperty<Real>("latent_specific_heat")),
    _L(getADMaterialProperty<Real>("latent_heat")),
    _T(adCoupledValue("temperature")),
    _Ts(getADMaterialProperty<Real>("starting_temperature")),
    _Te(getADMaterialProperty<Real>("ending_temperature"))
{
}

void
TwoPhaseChange::computeQpState()
{
  if (_Ts[_qp] < _Te[_qp])
  {
    if (_T[_qp] < _Ts[_qp])
    {
      _state[_qp] = PhaseChangeState::BEFORE;
      _phi[_qp] = 0;
    }
    else if (_T[_qp] >= _Ts[_qp] && _T[_qp] < _Te[_qp])
    {
      _state[_qp] = PhaseChangeState::TRANSITION;
      _phi[_qp] = (_T[_qp] - _Ts[_qp]) / (_Te[_qp] - _Ts[_qp]);
    }
    else if (_T[_qp] >= _Te[_qp])
    {
      _state[_qp] = PhaseChangeState::AFTER;
      _phi[_qp] = 1;
    }
    else
      mooseError("Internal error");
  }
  else
  {
    if (_T[_qp] < _Te[_qp])
    {
      _state[_qp] = PhaseChangeState::AFTER;
      _phi[_qp] = 0;
    }
    else if (_T[_qp] >= _Te[_qp] && _T[_qp] < _Ts[_qp])
    {
      _state[_qp] = PhaseChangeState::TRANSITION;
      _phi[_qp] = (_T[_qp] - _Te[_qp]) / (_Ts[_qp] - _Te[_qp]);
    }
    else if (_T[_qp] >= _Ts[_qp])
    {
      _state[_qp] = PhaseChangeState::BEFORE;
      _phi[_qp] = 1;
    }
    else
      mooseError("Internal error");
  }
}

void
TwoPhaseChange::computeQpLatentSpecificHeat()
{
  // Calculate the Gaussian function
  // std is chosen such that 95% latent heat is absorbed/released over the specified interval
  auto mu = (_Ts[_qp] + _Te[_qp]) / 2;
  auto dT = std::abs(_Te[_qp] - _Ts[_qp]);
  auto sigma = dT / 1.96 / 2;
  auto z = (_T[_qp] - mu) / sigma;
  auto G = 1 / sigma / std::sqrt(2 * M_PI) * std::exp(-z * z / 2);

  // The Gaussian function is effectively the "density" of latent heat
  // over the course of phase change.
  _cpL[_qp] = _L[_qp] * G;
}

void
TwoPhaseChange::initQpStatefulProperties()
{
  computeQpState();
  computeQpLatentSpecificHeat();
}

void
TwoPhaseChange::computeQpProperties()
{
  computeQpState();
  computeQpLatentSpecificHeat();
}
