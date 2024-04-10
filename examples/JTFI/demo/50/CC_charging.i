in = 5e-5
t0 = 60
t1 = 120
dtmax = 6

sigma_i_cam = 0.0005 #mS/mm
sigma_i_sse = 0.0023 #mS/mm
sigma_e_sse = 0.02 #mS/mm

c0 = 1e-4 #mmol/mm^3
cmax = 1e-3 #mmol/mm^3
c_ref_entropy = 1e-4
D_cam = 2e-10 #mm^2/s
D_sse = 6e-10 #mm^2/s

R = 8.3145 #mJ/mmol/K
T0 = 300 #K
F = 96485 #mC/mmol

i0 = 1e-1 #mA/mm^2
Phi_penalty = 10

[GlobalParams]
  energy_densities = 'dot(psi_c) q q_e zeta'
[]

[Mesh]
  [cathode]
    type = FileMeshGenerator
    file = 'gold/NMC_50pct.exo'
  []
  [rename_blocks]
    type = RenameBlockGenerator
    input = cathode
    old_block = 'electrolyte particles'
    new_block = 'SSE CAM'
  []
  [rename_boundaries]
    type = RenameBoundaryGenerator
    input = rename_blocks
    old_boundary = 'left_surf right_surf top_surf bot_surf'
    new_boundary = 'left right top bottom'
  []
  [scale]
    type = TransformGenerator
    input = rename_boundaries
    transform = SCALE
    vector_value = '1e-3 1e-3 1e-3'
  []
  [interfaces]
    type = BreakMeshByBlockGenerator
    input = scale
    add_interface_on_two_sides = true
    split_interface = true
  []
  use_displaced_mesh = false
[]

[Variables]
  [Phi_e]
    block = 'SSE'
  []
  [Phi]
  []
  [c]
  []
[]

[AuxVariables]
  [c_ref]
  []
  [T]
    initial_condition = ${T0}
  []
  [T_ref]
    initial_condition = ${T0}
  []
  [ir]
  []
[]

[ICs]
  [c_sse]
    type = ConstantIC
    variable = c
    value = ${c0}
    block = 'SSE'
  []
  [c_cam]
    type = ConstantIC
    variable = c
    value = '${fparse 0.9*cmax}'
    block = 'CAM'
  []
  [c_ref_sse]
    type = ConstantIC
    variable = c_ref
    value = ${c0}
    block = 'SSE'
  []
  [c_ref_cam]
    type = ConstantIC
    variable = c_ref
    value = ${c0}
    block = 'CAM'
  []
[]

[Kernels]
  # Charge balance
  [charge_balance_e]
    type = RankOneDivergence
    variable = Phi_e
    vector = i_e
    block = 'SSE'
  []
  [charge_balance]
    type = RankOneDivergence
    variable = Phi
    vector = i
    save_in = ir
  []
  # Mass balance
  [mass_balance_1]
    type = TimeDerivative
    variable = c
  []
  [mass_balance_2]
    type = RankOneDivergence
    variable = c
    vector = j
  []
[]

[InterfaceKernels]
  [current]
    type = MaterialInterfaceNeumannBC
    variable = Phi
    neighbor_var = Phi
    prop = ie
    factor = -1
    factor_neighbor = 1
    boundary = 'CAM_SSE'
  []
  [mass]
    type = MaterialInterfaceNeumannBC
    variable = c
    neighbor_var = c
    prop = je
    factor = -1
    factor_neighbor = 1
    boundary = 'CAM_SSE'
  []
  [continuity_Phi]
    type = InterfaceContinuity
    variable = Phi
    neighbor_var = Phi_e
    penalty = ${Phi_penalty}
    boundary = 'CAM_SSE'
  []
[]

[Functions]
  [in]
    type = PiecewiseLinear
    x = '${t0} ${t1}'
    y = '0 ${in}'
  []
  [U0]
    type = PiecewiseLinear
    data_file = '../gold/NMC.csv'
    format = columns
    x_title = c
    y_title = OCV
    extrap = true
  []
[]

[BCs]
  [current]
    type = FunctionNeumannBC
    variable = Phi_e
    boundary = right
    function = in
  []
  [potential]
    type = DirichletBC
    variable = Phi
    boundary = left
    value = 0
  []
[]

[Materials]
  # Electrodynamics
  [conductivity]
    type = ADPiecewiseConstantByBlockMaterial
    prop_name = 'sigma'
    subdomain_to_prop_value = 'CAM ${sigma_i_cam} SSE ${sigma_i_sse}'
  []
  [conductivity_e]
    type = ADPiecewiseConstantByBlockMaterial
    prop_name = 'sigma_e'
    subdomain_to_prop_value = 'SSE ${sigma_e_sse}'
    block = 'SSE'
  []
  [charge_transport]
    type = BulkChargeTransport
    electrical_energy_density = q
    electric_potential = Phi
    electric_conductivity = sigma
    temperature = T
  []
  [charge_transport_e]
    type = BulkChargeTransport
    electrical_energy_density = q_e
    electric_potential = Phi_e
    electric_conductivity = sigma_e
    temperature = T
    block = 'SSE'
  []
  [current_density]
    type = CurrentDensity
    current_density = i
    electric_potential = Phi
  []
  [current_density_e]
    type = CurrentDensity
    current_density = i_e
    electric_potential = Phi_e
    block = 'SSE'
  []
  # Chemical reactions
  [diffusivity]
    type = ADPiecewiseConstantByBlockMaterial
    prop_name = 'D'
    subdomain_to_prop_value = 'CAM ${D_cam} SSE ${D_sse}'
  []
  [mobility]
    type = ADParsedMaterial
    f_name = M
    args = 'c_ref T_ref'
    material_property_names = 'D'
    function = 'D*c_ref/${R}/T_ref'
  []
  [chemical_energy]
    type = EntropicChemicalEnergyDensity
    chemical_energy_density = psi_c
    concentration = c
    ideal_gas_constant = ${R}
    temperature = T_ref
    reference_concentration = ${c_ref_entropy}
    reference_chemical_potential = 0
  []
  [chemical_potential]
    type = ChemicalPotential
    chemical_potential = mu
    concentration = c
  []
  [diffusion]
    type = MassDiffusion
    dual_chemical_energy_density = zeta
    chemical_potential = mu
    mobility = M
  []
  [mass_flux]
    type = MassFlux
    mass_flux = j
    chemical_potential = mu
  []

  # Redox
  [ramp]
    type = ADGenericFunctionMaterial
    prop_names = 'ramp'
    prop_values = 'if(t<${t0},t/${t0},1)'
    boundary = 'CAM_SSE'
  []
  [OCP_cathode_NMC811_ramped]
    type = ADParsedMaterial
    property_name = U
    expression = 'U0*ramp'
    material_property_names = 'U0 ramp'
    boundary = 'CAM_SSE'
  []
  # [OCP_cathode_NMC811]
  #   type = ADParsedMaterial
  #   property_name = U0
  #   expression = 'x:=c/${cmax}; (6.0826-6.9922*x+7.1062*x^2-5.4549e-5*exp(124.23*x-114.2593)-2.5947*x^3)'
  #   coupled_variables = c
  #   boundary = 'CAM_SSE'
  # []
  [OCP_cathode_NMC811]
    type = ADCoupledValueFunctionMaterial
    prop_name = U0
    function = U0
    v = 'c'
    parameter_order = 'T'
    boundary = 'CAM_SSE'
  []
  [charge_transfer_cathode_elyte]
    type = ChargeTransferReaction
    charge_transfer_current_density = ie
    charge_transfer_mass_flux = je
    charge_transfer_heat_flux = he
    electric_potential = Phi
    neighbor_electric_potential = Phi
    charge_transfer_coefficient = 0.5
    exchange_current_density = ${i0}
    faraday_constant = ${F}
    ideal_gas_constant = ${R}
    temperature = T
    open_circuit_potential = U
    boundary = 'CAM_SSE'
  []
[]

[Postprocessors]
  [OCP]
    type = ADSideAverageMaterialProperty
    property = U
    boundary = 'CAM_SSE'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [c_CAM]
    type = ElementIntegralVariablePostprocessor
    variable = c
    block = 'CAM'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [c_SSE]
    type = ElementIntegralVariablePostprocessor
    variable = c
    block = 'SSE'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [I]
    type = NodalSum
    variable = ir
    boundary = 'left'
    outputs = none
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [C]
    type = TimeIntegratedPostprocessor
    value = I
    scale = -1
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [V1]
    type = SideAverageValue
    variable = Phi
    boundary = left
    outputs = none
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [V2]
    type = SideAverageValue
    variable = Phi_e
    boundary = right
    outputs = none
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [V]
    type = ParsedPostprocessor
    function = 'V2 - V1'
    pp_names = 'V2 V1'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [dC]
    type = ChangeOverTimePostprocessor
    postprocessor = C
    outputs = none
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [dV]
    type = ChangeOverTimePostprocessor
    postprocessor = V
    outputs = none
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [dCdV]
    type = ParsedPostprocessor
    function = 'dC/dV'
    pp_names = 'dC dV'
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[UserObjects]
  [kill_V]
    type = Terminator
    expression = 'V >= 4.6'
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON

  petsc_options = '-ksp_converged_reason'
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
  automatic_scaling = true
  verbose = true
  line_search = none

  l_max_its = 2
  l_tol = 1e-6
  nl_rel_tol = 1e-6
  nl_abs_tol = 1e-8
  nl_max_its = 12

  [Predictor]
    type = SimplePredictor
    scale = 1
  []
  [TimeStepper]
    type = IterationAdaptiveDT
    dt = '${fparse t0/50}'
    optimal_iterations = 6
    iteration_window = 1
    growth_factor = 1.2
    cutback_factor = 0.2
    cutback_factor_at_failure = 0.1
    linear_iteration_ratio = 100
  []
  dtmax = ${dtmax}
  end_time = 36000
[]

[Outputs]
  exodus = true
  csv = true
  print_linear_residuals = false
[]
