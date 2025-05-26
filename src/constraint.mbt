
///|
struct Constraint[V] {
  eq_poly : Array[(Poly[V], V)]
  ineq_poly : Array[(Poly[V], String, V)]
}derive()

///|
pub impl[V : Show + Eq + Semiring] Show for Constraint[V] with to_string (
  self : Constraint[V]
) -> String {
  let mut res = ""
  for x in self.eq_poly {
    res = x.0.to_string() + " = " + x.1.to_string() + "      "
  } 
  for x in self.ineq_poly {
    res = res + x.0.to_string() + " \{x.1} " + x.2.to_string() + "      "
  }
  "s.t.  " + res
}

pub impl[V : Show + Eq + Semiring] Show for Constraint[V] with output (
  self,
  l
) {
  l.write_string(self.to_string())
}

///|
/// poly_number : the constraint number this PL question used
pub fn Constraint::new[V]() -> Constraint[V] {
  let ep : Array[(Poly[V], V)] = []
  let iep : Array[(Poly[V], String, V)] = []
  {
    eq_poly : ep,
    ineq_poly : iep,
  }
}


pub fn Constraint::add_eqpoly[V](self : Constraint[V], poly : Poly[V], b : V) -> Unit {
  self.eq_poly.append([(poly, b)])
}

///|
/// s : '>=' or '<='
pub fn Constraint::add_ineqpoly[V] (self : Constraint[V], poly : Poly[V], s : String, b : V) -> Unit {
  self.ineq_poly.append([(poly, s, b)])
}

pub fn Constraint::change_eqpoly[V] (self : Constraint[V], index : Int, poly : Poly[V], b : V) -> Unit {
  guard (index > 0 && index < self.eq_poly.capacity()) else {abort("Error, index is out of bound")}
  self.eq_poly[index - 1] = (poly, b)
}

pub fn Constraint::change_ineqpoly[V] (self : Constraint[V], index : Int, poly : Poly[V], s : String, b : V) -> Unit {
  guard (index > 0 && index < self.eq_poly.capacity()) else {abort("Error, index is out of bound")}
  self.ineq_poly[index - 1] = (poly, s, b)
}

///|
pub fn Constraint::from_array[V : Eq + Compare + Semiring] (
  eqarray : Array[(Array[V], V)], 
  ineqArray : Array[(Array[V], String, V)], 
  vars : Array[Variable]
) -> Constraint[V] {
  let c = Constraint::new()
  for eq in eqarray {
    c.add_eqpoly(
      Poly::from_var_array(eq.0, vars), 
      eq.1
    )
  }
  for ineq in ineqArray {
    guard ineq.1 == ">=" || ineq.1 == "<=" else {abort("there is not '>=' or '<=' in ineq Array")}
    c.add_ineqpoly(
      Poly::from_var_array(ineq.0, vars),
      ineq.1,
      ineq.2
    )
  }
  c
} 

///|
// pub fn Constraint::from_matrix[V] (vars : Array[Variable]) -> Constraint[V] {
//   ...
// }

///|
// pub fn Constraint::to_matrix[V] (self : Constraint[V]) -> Matrix[V] {
//   ...
// }
