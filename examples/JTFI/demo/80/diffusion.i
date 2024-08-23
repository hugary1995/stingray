[Mesh]
  [cathode]
    type = FileMeshGenerator
    file = 'gold/NMC_80pct.exo'
  []
  [refine]
    type = RefineBlockGenerator
    input = cathode
    block = 'electrolyte particles'
    refinement = '0 0'
  []
  [rename_blocks]
    type = RenameBlockGenerator
    input = refine
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
  [remove]
    type = BlockDeletionGenerator
    input = scale
    block = 'CAM'
  []
  uniform_refine = 1
[]

[Variables]
  [u]
  []
  [v]
  []
[]

[Kernels]
  [diff_x]
    type = Diffusion
    variable = u
  []
  [diff_y]
    type = Diffusion
    variable = v
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
  [bottom]
    type = DirichletBC
    variable = v
    value = 0
    boundary = 'bottom'
  []
  [top]
    type = DirichletBC
    variable = v
    value = 1
    boundary = 'top'
  []
[]

[Executioner]
  type = Steady
  solve_type = NEWTON
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
[]

[Outputs]
  exodus = true
[]
