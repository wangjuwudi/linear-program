struct Lp[V] {
  vars : Array[Variable]
  obj_func : Obj_func[V]
  constraint : Constraint[V]
}

pub impl[V : Show + Eq + Semiring] Show for Lp[V] with to_string (
  self
) -> String {
  let mut s = self.obj_func.to_string() + "{/n}   " + self.constraint.to_string()
  for x in self.vars {
    s = s + "/n" + x.show_all()
  }
  s
}

pub impl[V : Show + Eq + Semiring] Show for Lp[V] with output (
  self,
  l
) -> Unit {
  l.write_string(self.to_string())
}

pub fn Lp::new[V] (s : String, poly : Poly[V], var : Array[Variable]) -> Lp[V] {
  {
    vars : var,
    obj_func : Obj_func::new(s).set_poly(poly),
    constraint : Constraint::new()
  }
}

///|
/// obj_func function: reset it by Array[V]
pub fn Lp::reset_obj_byarray[V : Eq + Compare + Semiring] (self : Lp[V], arr: Array[V]) -> Lp[V] {
  {
    vars : self.vars, 
    obj_func : self.obj_func.set_poly(Poly::from_var_array(arr, self.vars)),
    constraint : self.constraint
  }
}

///|
/// set constraint by Array
/// the lable in ineq_array must be ">=" or "<="
pub fn Lp::cons_from_Array[V : Eq + Compare + Semiring] (
  self : Lp[V], 
  eq_array : Array[(Array[V],V)], 
  ineq_array : Array[(Array[V], String, V)]
) -> Lp[V] {
  {
    vars : self.vars,
    obj_func : self.obj_func,
    constraint : Constraint::from_array(eq_array, ineq_array, self.vars)
  }
}

// pub fn Lp::from_matrix[V] (self : Lp[V]) -> Unit{
// ...
// }

test "show" {
  let arr = [
    Variable::new("x1", 0.0, 100.0),
    Variable::new("x2", 0.0, 100.0),
    Variable::new("x3", 0.0, 100.0)
  ]
  let obj_poly = Poly::from_var_array(
    [1.0, 2.0, 3.0],
    arr
  )
  println(obj_poly)

  let eqarr = [
    ([2.0, 2.0, 3.0], 100.0)
  ]
  let ineqarr = [
    ([2.5, 3.3, 4.7], ">=", 0.0),
    ([-1.7, 2.5, 12], "<=", 0.0)
  ]

  let lp = Lp::new("min", obj_poly, arr)
  println(lp)
  println(lp.cons_from_Array(eqarr, ineqarr))
}