ell = 10

[Mesh]
  [fmg]
    type = FileMeshGenerator
    file = '../cell.msh'
  []
  [sides]
    type = SideSetsFromNormalsGenerator
    input = fmg
    new_boundary = 'left right top bottom'
    normals = '-1 0 0 1 0 0 0 1 0 0 -1 0'
    fixed_normal = true
  []
[]

[Variables]
  [u]
  []
[]

[Kernels]
  [diff]
    type = MatDiffusion
    variable = u
    diffusivity = D
  []
[]

[UserObjects]
  [fields]
    type = SolutionUserObject
    mesh = '${ell}/fields.e'
  []
[]

[AuxVariables]
  [D]
    [AuxKernel]
      type = SolutionAux
      solution = 'fields'
      from_variable = 'si'
      block = 'elyte'
    []
  []
[]

[Materials]
  [D_cam]
    type = GenericFunctionMaterial
    prop_names = 'D'
    prop_values = '1'
    block = 'cam'
  []
  [D_elyte]
    type = ParsedMaterial
    property_name = 'D'
    expression = 'D'
    coupled_variables = 'D'
    block = 'elyte'
  []
[]

[BCs]
  [left]
    type = DirichletBC
    variable = u
    value = 0
    boundary = 'left'
  []
  [right]
    type = DirichletBC
    variable = u
    value = 1
    boundary = 'right'
  []
[]

[Executioner]
  type = Steady
  solve_type = NEWTON
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
  automatic_scaling = true
[]

[Outputs]
  file_base = '${ell}/diffusion'
  exodus = true
[]
