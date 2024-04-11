in = 3e-4
t0 = 60
t1 = 120
dtmax = 6

sigma_i_cam = 0.0005 #mS/mm
sigma_i_sse = 0.0023 #mS/mm
sigma_e_sse = 0.02 #mS/mm

c0 = 1e-4 #mmol/mm^3
cmax = 1e-3 #mmol/mm^3
c_ref_entropy = 1e-4
M_cam = 8e-16 #
M_sse = 2.4e-15 #

R = 8.3145 #mJ/mmol/K
T0 = 300 #K
F = 96485 #mC/mmol

i0 = 1e-1 #mA/mm^2
Phi_penalty = 10

E_cam = 6e4
E_sse = 5e4
nu_cam = 0.3
nu_sse = 0.25

u_penalty = 1e7
Omega = 20.33
beta = 0.9

[GlobalParams]
  energy_densities = 'dot(psi_m) dot(psi_c) q q_e zeta m'
  displacements = 'disp_x disp_y'
  deformation_gradient = F
  mechanical_deformation_gradient = Fm
  eigen_deformation_gradient = Fg
  swelling_deformation_gradient = Fs
[]

[Mesh]
  [cathode]
    type = FileMeshGenerator
    file = 'gold/NMC_80pct.exo'
  []
  [refine]
    type = RefineBlockGenerator
    input = cathode
    block = 'electrolytes particles'
    refinement = '0 0'
  []
  [rename_blocks]
    type = RenameBlockGenerator
    input = refine
    old_block = 'electrolytes particles'
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
  [disp_x]
  []
  [disp_y]
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
  [sigmah]
    order = CONSTANT
    family = MONOMIAL
    [AuxKernel]
      type = ADRankTwoScalarAux
      rank_two_tensor = pk1
      scalar_type = Hydrostatic
      execute_on = 'INITIAL TIMESTEP_END'
    []
  []
  [sigmavm]
    order = CONSTANT
    family = MONOMIAL
    [AuxKernel]
      type = ADRankTwoScalarAux
      rank_two_tensor = pk1
      scalar_type = VonMisesStress
      execute_on = 'INITIAL TIMESTEP_END'
    []
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
    value = '${cmax}'
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
    value = ${cmax}
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
  # Momentum balance
  [momentum_balance_x]
    type = RankTwoDivergence
    variable = disp_x
    component = 0
    tensor = pk1
    factor = -1
  []
  [momentum_balance_y]
    type = RankTwoDivergence
    variable = disp_y
    component = 1
    tensor = pk1
    factor = -1
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
  [continuity_disp_x]
    type = InterfaceContinuity
    variable = disp_x
    neighbor_var = disp_x
    penalty = ${u_penalty}
    boundary = 'CAM_SSE'
  []
  [continuity_disp_y]
    type = InterfaceContinuity
    variable = disp_y
    neighbor_var = disp_y
    penalty = ${u_penalty}
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
    data_file = '../gold/OCV.csv'
    format = columns
    x_title = c
    y_title = OCV
    extrap = true
  []
  [Ms]
    type = PiecewiseLinear
    data_file = '../gold/M.csv'
    format = columns
    x_title = c
    y_title = M
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
  [fix_x]
    type = DirichletBC
    variable = disp_x
    value = 0
    boundary = 'left'
  []
  [fix_y]
    type = DirichletBC
    variable = disp_y
    value = 0
    boundary = 'bottom'
  []
[]

[Constraints]
  [current_collector]
    type = EqualValueBoundaryConstraint
    variable = Phi_e
    penalty = 100
    secondary = right
  []
  [ev_x]
    type = EqualValueBoundaryConstraint
    variable = disp_x
    penalty = ${u_penalty}
    secondary = right
  []
  [ev_y]
    type = EqualValueBoundaryConstraint
    variable = disp_y
    penalty = ${u_penalty}
    secondary = top
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
  [mobility_0]
    type = ADPiecewiseConstantByBlockMaterial
    prop_name = M0
    subdomain_to_prop_value = 'CAM ${M_cam} SSE ${M_sse}'
  []
  [mobility_scale]
    type = ADCoupledValueFunctionMaterial
    prop_name = Ms
    function = Ms
    v = 'c'
    parameter_order = 'T'
  []
  [mobility]
    type = ADParsedMaterial
    property_name = 'M'
    expression = 'M0*Ms'
    material_property_names = 'M0 Ms'
  []
  [chemical_energy]
    type = EntropicChemicalEnergyDensity
    chemical_energy_density = psi_c
    concentration = c
    ideal_gas_constant = ${R}
    temperature = T_ref
    reference_concentration = ${c_ref_entropy}
    reference_chemical_potential = 1e3
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
    output_properties = 'j'
    outputs = 'exodus'
  []

  # Migration
  # [migration]
  #   type = Migration
  #   electrochemical_energy_density = m
  #   electric_potential = Phi
  #   chemical_potential = mu
  #   electric_conductivity = sigma
  #   faraday_constant = ${F}
  # []

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

  # Mechanical
  [E]
    type = ADPiecewiseConstantByBlockMaterial
    prop_name = 'E'
    subdomain_to_prop_value = 'CAM ${E_cam} SSE ${E_sse}'
  []
  [nu]
    type = ADPiecewiseConstantByBlockMaterial
    prop_name = 'nu'
    subdomain_to_prop_value = 'CAM ${nu_cam} SSE ${nu_sse}'
  []
  [lambda]
    type = ADParsedMaterial
    property_name = lambda
    expression = 'E*nu/(1+nu)/(1-2*nu)'
    material_property_names = 'E nu'
  []
  [G]
    type = ADParsedMaterial
    property_name = G
    expression = 'E/2/(1+nu)'
    material_property_names = 'E nu'
  []
  [swelling_coefficient]
    type = ADGenericConstantMaterial
    prop_names = 'beta'
    prop_values = '${beta}'
  []
  [swelling]
    type = SwellingDeformationGradient
    concentration = c
    reference_concentration = c_ref
    molar_volume = ${Omega}
    swelling_coefficient = beta
  []
  [defgrad]
    type = MechanicalDeformationGradient
  []
  [neohookean]
    type = NeoHookeanSolid
    elastic_energy_density = psi_m
    lambda = lambda
    shear_modulus = G
    concentration = c
    temperature = T
    non_swelling_pressure = p
  []
  [pk1]
    type = FirstPiolaKirchhoffStress
    first_piola_kirchhoff_stress = pk1
    deformation_gradient_rate = dot(F)
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
  [Ineg]
    type = ParsedPostprocessor
    function = '-I'
    pp_names = 'I'
    outputs = none
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [C]
    type = TimeIntegratedPostprocessor
    value = Ineg
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
  [cmin]
    type = NodalExtremeValue
    variable = c
    value_type = min
    block = 'CAM'
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[UserObjects]
  # [kill_V]
  #   type = Terminator
  #   expression = 'V >= 4.4'
  # []
  [kill_cmin]
    type = Terminator
    expression = 'cmin < 1e-10'
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

  l_max_its = 100
  l_tol = 1e-6
  nl_rel_tol = 1e-6
  nl_abs_tol = 1e-8
  nl_max_its = 12

  reuse_preconditioner = true
  reuse_preconditioner_max_linear_its = 25

  # [Predictor]
  #   type = SimplePredictor
  #   scale = 1
  # []
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
