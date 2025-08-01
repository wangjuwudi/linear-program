///|
type Poly[V] @sorted_map.T[Variable, V] derive(Eq)

///|
pub impl[V : Eq + Show + Semiring + One] Show for Poly[V] with output(self, l) {
  let mut fst = true
  self
  .inner()
  .each(fn(variable, coff) -> Unit {
    if fst {
      fst = false
    } else {
      l.write_string(" + ")
    }
    if coff == V::one() {
      l.write_object(variable)
    } else if coff != V::zero() {
      l.write_object(coff)
      l.write_object(variable)
    }
  })
}

///|
pub impl[V : Eq + Semiring + Zero + Neg] Neg for Poly[V] with op_neg(
  self : Poly[V],
) -> Poly[V] {
  let m = Poly::new()
  self
  .inner()
  .each(fn(variable : Variable, coeff : V) -> Unit {
    m.add_term_inplace(variable, -coeff)
  })
  m
}

///|
test "Neg" {
  let x1 : Variable = { name: "x1", low_bound: -1.0, up_bound: 1.0 }
  let x2 : Variable = { name: "x2", low_bound: -1.0, up_bound: 1.0 }
  let x3 : Variable = { name: "x3", low_bound: -1.0, up_bound: 1.0 }
  let poly = Poly::new()
  poly.add_term_inplace(x1, 3.5)
  poly.add_term_inplace(x2, 1.5)
  poly.add_term_inplace(x3, -2)
  inspect(poly, content="3.5x1 + 1.5x2 + -2x3")
  inspect(-poly, content="-3.5x1 + -1.5x2 + 2x3")
  inspect(-(-poly), content="3.5x1 + 1.5x2 + -2x3")
}

///|
pub fn[V] Poly::new() -> Poly[V] {
  @sorted_map.new()
}

///|
pub fn[V : Eq + Semiring] Poly::from_var_array(
  arr : Array[V],
  vars : Array[Variable],
) -> Poly[V] {
  let res = Poly::new()
  for index, x in arr {
    if index < vars.length() && x != V::zero() {
      res.inner().add(vars[index], x)
    }
    if index >= vars.length() {
      res.inner().add(Variable::one(), x)
    }
  }
  res
}

///|
pub fn[V] Poly::to_array(self : Poly[V]) -> Array[V] {
  let res : Array[V] = []
  for x in self.inner() {
    res.push(x.1)
  }
  res
}

///|
pub fn[V : Zero] Poly::to_vector(
  self : Poly[V],
  vars : Array[Variable],
) -> Array[V] {
  let res : Array[V] = []
  for variable in vars {
    res.push(
      match self.inner().get(variable) {
        None => V::zero()
        Some(x) => x
      },
    )
  }
  res
}

///|
pub fn[V : Eq + Semiring + Zero] Poly::add_term_inplace(
  self : Poly[V],
  variable : Variable,
  coeff : V,
) -> Unit {
  guard coeff != V::zero() else { return }
  if self.inner().get(variable) is None {
    self.inner().add(variable, coeff)
  } else {
    let new_coeff = self.inner().get(variable).unwrap() + coeff
    guard new_coeff != V::zero() else { self.inner().remove(variable) }
    self.inner()[variable] = new_coeff
  }
}

///|
pub fn[V : Eq + Semiring + Zero] Poly::copy(self : Poly[V]) -> Poly[V] {
  let m = Poly::new()
  self
  .inner()
  .each(fn(variable : Variable, coeff : V) -> Unit {
    m.add_term_inplace(variable, coeff)
  })
  m
}
