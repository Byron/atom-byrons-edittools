describe "Aster", ->
  v = null
  # fn name((mut x, &y): (u32, usize)) -> u8 {
  #     42
  # }
  root =
    function:
      fn: v
      name: v
      arguments:
        1:
          'mut x': v
          '&y': v
        2:
          u32: v
          usize: v
      return:
        u8: v
      body:
        '42': v
