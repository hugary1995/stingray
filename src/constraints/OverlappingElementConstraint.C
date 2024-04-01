// Copyright 2023, UChicago Argonne, LLC All Rights Reserved
// License: L-GPL 3.0

#include "OverlappingElementConstraint.h"

InputParameters
OverlappingElementConstraint::validParams()
{
  InputParameters params = ElemElemConstraint::validParams();
  params.addRequiredParam<SubdomainName>("primary", "primary block id");
  params.addRequiredParam<std::vector<SubdomainName>>("secondary", "list of secondary block ids");

  return params;
}

OverlappingElementConstraint::OverlappingElementConstraint(const InputParameters & parameters)
  : ElemElemConstraint(parameters),
    _primary(_mesh.getSubdomainID(getParam<SubdomainName>("primary")))
{
  for (auto sec : getParam<std::vector<SubdomainName>>("secondary"))
    _secondary.push_back(_mesh.getSubdomainID(sec));

  auto oepl = std::make_shared<OverlappingElementPairLocator>(
      &_mesh, &_assembly, &_fe_problem, _primary, _secondary);
  oepl->reinit();
  _fe_problem.geomSearchData().addElementPairLocator(_interface_id, oepl);
}

void
OverlappingElementConstraint::initialSetup()
{
}
