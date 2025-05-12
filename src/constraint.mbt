
///|
struct Constraint[V] {
  eq_poly : Array[(Poly[V], V)]
  ineq_poly : Array[(Poly[V], String, V)]
}derive()

///|
pub impl[V : Show + Eq + Semiring] Show for Constraint[V] with to_string (
  self : Constraint[V]
) -> String {
  let mut res = "s.t.  "
  for x in self.eq_poly {
    res = x.1.to_string() + " = " + x.1.to_string() + "//n      "
  } 
  for x in self.ineq_poly {
    res = res + x.0.to_string() + " \{x.1} " + x.2.to_string() + "//n      "
  }
  res
}

pub impl[V : Show + Eq + Semiring] Show for Constraint[V] with output (
  self,
  l
) {
  l.write_string(self.to_string())
}

///|
/// var_number : the number this PL question used
pub fn Constraint::new[V](poly_number : Int) -> Constraint[V] {
  let ep : Array[(Poly[V], V)] = Array::new(capacity = poly_number )
  let iep : Array[(Poly[V], String, V)] = Array::new(capacity = poly_number)
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
pub fn Constraint::from_matrix[V] (vars : Array[Variable]) -> Constraint[V] {
  ...
}

///|
pub fn Constraint::to_matrix[V] (self : Constraint[V]) -> Matrix[V] {
  ...
}
