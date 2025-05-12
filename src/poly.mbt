type Poly[V] @sorted_map.T[Variable, V] derive(Eq)



pub impl[V : Eq + Show + Semiring + @lg.One] Show for Poly[V] with to_string (
  self
) -> String {
  let mut s = ""
  let mut fst = true
  self._.each(fn (var, coff) -> Unit {
    if not(fst) {
      s += " + "
    }
    if coff == V::one(){
      s += var.to_string()
    }else if coff == V::zero() {
      s += ""
    }else {
      s += coff.to_string()
      s += var.to_string()
    } 
    fst = false
  })
  s
}

pub impl[V : Eq + Show + Semiring + One] Show for Poly[V] with output(
  self,
  l
) {
  l.write_string(self.to_string())
}

pub impl[V: Eq + Semiring + Compare + Zero + Neg] Neg for Poly[V] with op_neg (
  self : Poly[V]
) -> Poly[V] {
  let m = Poly::new()
  self._.each(
    fn (var : Variable, coeff : V) -> Unit {
      m.add_term_inplace(var, -coeff)
    }
  )
  m
}


pub fn Poly::new[V] () -> Poly[V] {
  @sorted_map.new()
}

pub fn Poly::from_Array[V: Eq + Semiring + Compare] (
  arr : Array[(Variable, V)]
) -> Poly[V] {
  let poly = Poly::new()
  for x in arr {
    poly.add_term_inplace(x.0, x.1)
  }
  poly
}

pub fn Poly::add_term_inplace[V: Eq + Semiring + Compare + Zero] (
  self : Poly[V],
  var : Variable, 
  coeff : V
) -> Unit {
  guard coeff != V::zero() else { return }
  if self._[var] is None {
    self._.add(var, coeff)
  }else{
    let new_coeff = self._[var].unwrap() + coeff
    guard new_coeff != V::zero() else { self._.remove(var) }
    self._[var] = new_coeff  
  }
}

pub fn Poly::copy[V: Eq + Semiring + Compare + Zero] (self : Poly[V]) -> Poly[V] {
  let m = Poly::new()
  self._.each(
    fn (var : Variable, coeff : V) -> Unit {
      m.add_term_inplace(var, coeff)
    }
  )
  m
}
