A Moonbit library for defining and solving linear programming problems

/** how to define a linear-program */      
(1) general step       
1. define variables_array  
2. define object_func  
3. define eq_constraint  
4. define ineq_constraint  
5. define linear-program  
```moonbit
let arr = [
    Variable::new("x1", 0.0, 100.0),
    Variable::new("x2", 0.0, 100.0),
    Variable::new("x3", 0.0, 100.0),
  ]
let obj_func = Obj_func::from_array("max", [1.0, 2.0, 3.0], arr)
let eqarr = [([2.0, 2.0, 3.0], 100.0)]
let ineqarr = [([2.5, 0.0, 4.7], ">=", 0.0), ([-1.7, 2.5, 12], "<=", 0.0)]
let lp2 = Lp::new(obj_func, arr).cons_from_Array(
    eq_array=eqarr,
    ineq_array=ineqarr,
)
```
(2) matrix to linear-program       
only contain Eq-constraint, don't contain Ineq-constraint      
```moonbit
let vars = [
  Variable::new("x1", 0.0, @double.max_value),
  Variable::new("x2", 0.0, @double.max_value),
  Variable::new("x3", 0.0, @double.max_value),
  Variable::new("x4", 0.0, @double.max_value),
]

let matrix = Matrix::from_2d_array([
  [1, 2, 3, 4, 0],
  [4, 1, 0, 6, 1],
  [1, 3, 1, 0, 0],
  [-1, 4, 7, 1, 2]
])

let lp = Lp::from_matrix(matrix, vars, "min")
```
