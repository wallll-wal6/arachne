///|
/// A deliberately small, first-party ASCII regex reference backend. It is
/// intended for differential fixtures, not as a replacement for a full regex
/// implementation. Groups are structural only; capture values are not exposed.
pub fn reference_ascii_adapter() -> EngineAdapter {
  EngineAdapter::new(id="arachne/reference-nfa (ASCII)", compile=pattern => {
    if !reference_is_ascii(pattern) {
      return Err("reference-domain: patterns must contain ASCII characters")
    }
    let chars = pattern.to_array()
    if chars.length() > 4096 {
      return Err("reference-limit: pattern exceeds 4096 characters")
    }
    let parser : ReferenceParser = { chars, index: 0, }
    let ast = match reference_parse_expression(parser) {
      Err(message) => return Err(message)
      Ok(node) => node
    }
    if parser.index != chars.length() {
      return Err("syntax: unexpected closing parenthesis")
    }
    let nfa = reference_compile(ast)
    Ok(
      CompiledMatcher::new(observe=input => {
        if !reference_is_ascii(input) {
          return Err("reference-domain: inputs must contain ASCII characters")
        }
        let input_chars = input.to_array()
        if input_chars.length() > 16384 {
          return Err("reference-limit: input exceeds 16384 characters")
        }
        match reference_find(nfa, input_chars) {
          None => Ok(None)
          Some((start, end)) =>
            Ok(
              Some({
                text: input[start:end].to_owned(),
                start,
                end,
                captures: [],
              }),
            )
        }
      }),
    )
  })
}

///|
fn reference_is_ascii(value : String) -> Bool {
  for char in value {
    if char.to_int() > 127 {
      return false
    }
  }
  true
}

///|
priv enum ReferencePredicate {
  Literal(Char)
  Any
  Ranges(Array[(Int32, Int32)], Bool)
}

///|
priv enum ReferenceNode {
  Empty
  Consume(ReferencePredicate)
  Begin
  End
  Sequence(Array[ReferenceNode])
  Choice(Array[ReferenceNode])
  ZeroOrMore(ReferenceNode)
  OneOrMore(ReferenceNode)
  Optional(ReferenceNode)
}

///|
priv struct ReferenceParser {
  chars : Array[Char]
  mut index : Int32
}

///|
fn reference_peek(parser : ReferenceParser) -> Char? {
  if parser.index < parser.chars.length() {
    Some(parser.chars[parser.index])
  } else {
    None
  }
}

///|
fn reference_take(parser : ReferenceParser) -> Char? {
  match reference_peek(parser) {
    None => None
    Some(char) => {
      parser.index = parser.index + 1
      Some(char)
    }
  }
}

///|
fn reference_parse_expression(
  parser : ReferenceParser,
) -> Result[ReferenceNode, String] {
  let alternatives : Array[ReferenceNode] = []
  match reference_parse_sequence(parser) {
    Err(message) => return Err(message)
    Ok(node) => alternatives.push(node)
  }
  while reference_peek(parser) == Some('|') {
    parser.index = parser.index + 1
    match reference_parse_sequence(parser) {
      Err(message) => return Err(message)
      Ok(node) => alternatives.push(node)
    }
  }
  if alternatives.length() == 1 {
    Ok(alternatives[0])
  } else {
    Ok(ReferenceNode::Choice(alternatives))
  }
}

///|
fn reference_parse_sequence(
  parser : ReferenceParser,
) -> Result[ReferenceNode, String] {
  let parts : Array[ReferenceNode] = []
  while (match reference_peek(parser) {
          Some(')') | Some('|') | None => false
          _ => true
        }) {
    match reference_parse_repetition(parser) {
      Err(message) => return Err(message)
      Ok(node) => parts.push(node)
    }
  }
  if parts.is_empty() {
    Ok(ReferenceNode::Empty)
  } else if parts.length() == 1 {
    Ok(parts[0])
  } else {
    Ok(ReferenceNode::Sequence(parts))
  }
}

///|
fn reference_parse_repetition(
  parser : ReferenceParser,
) -> Result[ReferenceNode, String] {
  let atom = match reference_parse_atom(parser) {
    Err(message) => return Err(message)
    Ok(node) => node
  }
  let repeated = match reference_peek(parser) {
    Some('*') => {
      parser.index = parser.index + 1
      Some(ReferenceNode::ZeroOrMore(atom))
    }
    Some('+') => {
      parser.index = parser.index + 1
      Some(ReferenceNode::OneOrMore(atom))
    }
    Some('?') => {
      parser.index = parser.index + 1
      Some(ReferenceNode::Optional(atom))
    }
    _ => None
  }
  let has_stacked_quantifier = match reference_peek(parser) {
    Some('*') | Some('+') | Some('?') | Some('{') => true
    _ => false
  }
  if repeated is Some(_) && has_stacked_quantifier {
    return Err("syntax: stacked or counted quantifiers are unsupported")
  }
  match repeated {
    Some(node) => Ok(node)
    None => Ok(atom)
  }
}

///|
fn reference_parse_atom(
  parser : ReferenceParser,
) -> Result[ReferenceNode, String] {
  match reference_take(parser) {
    None => Err("syntax: expected an expression")
    Some('(') => {
      if reference_peek(parser) == Some('?') {
        return Err("syntax: lookaround and special groups are unsupported")
      }
      let inside = match reference_parse_expression(parser) {
        Err(message) => return Err(message)
        Ok(node) => node
      }
      match reference_take(parser) {
        Some(')') => Ok(inside)
        _ => Err("syntax: unclosed group")
      }
    }
    Some('[') => reference_parse_class(parser)
    Some('.') => Ok(ReferenceNode::Consume(ReferencePredicate::Any))
    Some('^') => Ok(ReferenceNode::Begin)
    Some('$') => Ok(ReferenceNode::End)
    Some('\\') => reference_parse_escape(parser)
    Some(')') => Err("syntax: unexpected closing parenthesis")
    Some('|') => Err("syntax: missing expression before alternation")
    Some('*') | Some('+') | Some('?') =>
      Err("syntax: quantifier has no preceding expression")
    Some('{') => Err("syntax: counted quantifiers are unsupported")
    Some(char) => Ok(ReferenceNode::Consume(ReferencePredicate::Literal(char)))
  }
}

///|
fn reference_parse_escape(
  parser : ReferenceParser,
) -> Result[ReferenceNode, String] {
  match reference_take(parser) {
    None => Err("syntax: trailing escape")
    Some('d') =>
      Ok(
        ReferenceNode::Consume(
          ReferencePredicate::Ranges([('0'.to_int(), '9'.to_int())], false),
        ),
      )
    Some('D') =>
      Ok(
        ReferenceNode::Consume(
          ReferencePredicate::Ranges([('0'.to_int(), '9'.to_int())], true),
        ),
      )
    Some('w') =>
      Ok(
        ReferenceNode::Consume(
          ReferencePredicate::Ranges(
            [
              ('0'.to_int(), '9'.to_int()),
              ('A'.to_int(), 'Z'.to_int()),
              ('_'.to_int(), '_'.to_int()),
              ('a'.to_int(), 'z'.to_int()),
            ],
            false,
          ),
        ),
      )
    Some('W') =>
      Ok(
        ReferenceNode::Consume(
          ReferencePredicate::Ranges(
            [
              ('0'.to_int(), '9'.to_int()),
              ('A'.to_int(), 'Z'.to_int()),
              ('_'.to_int(), '_'.to_int()),
              ('a'.to_int(), 'z'.to_int()),
            ],
            true,
          ),
        ),
      )
    Some('s') =>
      Ok(
        ReferenceNode::Consume(
          ReferencePredicate::Ranges(
            [('\t'.to_int(), '\r'.to_int()), (' '.to_int(), ' '.to_int())],
            false,
          ),
        ),
      )
    Some('S') =>
      Ok(
        ReferenceNode::Consume(
          ReferencePredicate::Ranges(
            [('\t'.to_int(), '\r'.to_int()), (' '.to_int(), ' '.to_int())],
            true,
          ),
        ),
      )
    Some('n') => Ok(ReferenceNode::Consume(ReferencePredicate::Literal('\n')))
    Some('r') => Ok(ReferenceNode::Consume(ReferencePredicate::Literal('\r')))
    Some('t') => Ok(ReferenceNode::Consume(ReferencePredicate::Literal('\t')))
    Some(char) =>
      if (char >= '0' && char <= '9') ||
        (char >= 'a' && char <= 'z') ||
        (char >= 'A' && char <= 'Z') {
        Err("syntax: unsupported alphanumeric escape")
      } else {
        Ok(ReferenceNode::Consume(ReferencePredicate::Literal(char)))
      }
  }
}

///|
fn reference_parse_class(
  parser : ReferenceParser,
) -> Result[ReferenceNode, String] {
  let negated = if reference_peek(parser) == Some('^') {
    parser.index = parser.index + 1
    true
  } else {
    false
  }
  let ranges : Array[(Int32, Int32)] = []
  while reference_peek(parser) != Some(']') {
    let start = match reference_class_char(parser) {
      Err(message) => return Err(message)
      Ok(char) => char.to_int()
    }
    if reference_peek(parser) == Some('-') &&
      parser.index + 1 < parser.chars.length() &&
      parser.chars[parser.index + 1] != ']' {
      parser.index = parser.index + 1
      let end = match reference_class_char(parser) {
        Err(message) => return Err(message)
        Ok(char) => char.to_int()
      }
      if end < start {
        return Err("syntax: descending character-class range")
      }
      ranges.push((start, end))
    } else {
      ranges.push((start, start))
    }
  }
  if ranges.is_empty() {
    return Err("syntax: empty character class")
  }
  match reference_take(parser) {
    Some(']') =>
      Ok(ReferenceNode::Consume(ReferencePredicate::Ranges(ranges, negated)))
    _ => Err("syntax: unclosed character class")
  }
}

///|
fn reference_class_char(parser : ReferenceParser) -> Result[Char, String] {
  match reference_take(parser) {
    None => Err("syntax: unclosed character class")
    Some('\\') =>
      match reference_take(parser) {
        Some(']') => Ok(']')
        Some('-') => Ok('-')
        Some('\\') => Ok('\\')
        Some(_) => Err("syntax: unsupported escape in character class")
        None => Err("syntax: trailing escape in character class")
      }
    Some(']') => Err("syntax: empty character class")
    Some(char) => Ok(char)
  }
}

///|
priv enum ReferenceStateKind {
  Epsilon
  Split
  Consume(ReferencePredicate)
  Begin
  End
  Accept
}

///|
priv struct ReferenceState {
  kind : ReferenceStateKind
  mut out1 : Int32
  mut out2 : Int32
}

///|
priv struct ReferenceFragment {
  start : Int32
  pending : Array[(Int32, Int32)]
}

///|
priv struct ReferenceBuilder {
  states : Array[ReferenceState]
}

///|
fn reference_state(
  builder : ReferenceBuilder,
  kind : ReferenceStateKind,
) -> Int32 {
  let index = builder.states.length()
  builder.states.push({ kind, out1: -1, out2: -1, })
  index
}

///|
fn reference_pending(state : Int32, edge : Int32) -> Array[(Int32, Int32)] {
  [(state, edge)]
}

///|
fn reference_patch(
  builder : ReferenceBuilder,
  pending : Array[(Int32, Int32)],
  target : Int32,
) -> Unit {
  for (state_index, edge) in pending {
    let old = builder.states[state_index]
    if edge == 1 {
      old.out1 = target
    } else {
      old.out2 = target
    }
    builder.states[state_index] = old
  }
}

///|
fn reference_append(
  left : Array[(Int32, Int32)],
  right : Array[(Int32, Int32)],
) -> Array[(Int32, Int32)] {
  for item in right {
    left.push(item)
  }
  left
}

///|
fn reference_compile_node(
  builder : ReferenceBuilder,
  node : ReferenceNode,
) -> ReferenceFragment {
  match node {
    Empty => {
      let state = reference_state(builder, ReferenceStateKind::Epsilon)
      { start: state, pending: reference_pending(state, 1), }
    }
    Consume(predicate) => {
      let state = reference_state(
        builder,
        ReferenceStateKind::Consume(predicate),
      )
      { start: state, pending: reference_pending(state, 1), }
    }
    Begin => {
      let state = reference_state(builder, ReferenceStateKind::Begin)
      { start: state, pending: reference_pending(state, 1), }
    }
    End => {
      let state = reference_state(builder, ReferenceStateKind::End)
      { start: state, pending: reference_pending(state, 1), }
    }
    Sequence(nodes) => {
      let mut compiled : ReferenceFragment? = None
      for child in nodes {
        let next = reference_compile_node(builder, child)
        match compiled {
          None => compiled = Some(next)
          Some(previous) => {
            reference_patch(builder, previous.pending, next.start)
            compiled = Some({ start: previous.start, pending: next.pending, })
          }
        }
      }
      compiled.unwrap()
    }
    Choice(nodes) => {
      let mut compiled : ReferenceFragment? = None
      for child in nodes {
        let next = reference_compile_node(builder, child)
        match compiled {
          None => compiled = Some(next)
          Some(previous) => {
            let split = reference_state(builder, ReferenceStateKind::Split)
            let split_state = builder.states[split]
            split_state.out1 = previous.start
            split_state.out2 = next.start
            builder.states[split] = split_state
            compiled = Some({
              start: split,
              pending: reference_append(previous.pending, next.pending),
            })
          }
        }
      }
      compiled.unwrap()
    }
    ZeroOrMore(child) => {
      let body = reference_compile_node(builder, child)
      let split = reference_state(builder, ReferenceStateKind::Split)
      let split_state = builder.states[split]
      split_state.out1 = body.start
      builder.states[split] = split_state
      reference_patch(builder, body.pending, split)
      { start: split, pending: reference_pending(split, 2), }
    }
    OneOrMore(child) => {
      let body = reference_compile_node(builder, child)
      let split = reference_state(builder, ReferenceStateKind::Split)
      let split_state = builder.states[split]
      split_state.out1 = body.start
      builder.states[split] = split_state
      reference_patch(builder, body.pending, split)
      { start: body.start, pending: reference_pending(split, 2), }
    }
    Optional(child) => {
      let body = reference_compile_node(builder, child)
      let split = reference_state(builder, ReferenceStateKind::Split)
      let split_state = builder.states[split]
      split_state.out1 = body.start
      builder.states[split] = split_state
      {
        start: split,
        pending: reference_append(body.pending, reference_pending(split, 2)),
      }
    }
  }
}

///|
fn reference_compile(node : ReferenceNode) -> ReferenceNfa {
  let builder : ReferenceBuilder = { states: [], }
  let fragment = reference_compile_node(builder, node)
  let accept = reference_state(builder, ReferenceStateKind::Accept)
  reference_patch(builder, fragment.pending, accept)
  { states: builder.states, start: fragment.start, }
}

///|
priv struct ReferenceNfa {
  states : Array[ReferenceState]
  start : Int32
}

///|
fn reference_matches(predicate : ReferencePredicate, char : Char) -> Bool {
  match predicate {
    Literal(expected) => char == expected
    Any => char != '\n' && char != '\r'
    Ranges(ranges, negated) => {
      let value = char.to_int()
      let mut found = false
      for (start, end) in ranges {
        if value >= start && value <= end {
          found = true
        }
      }
      if negated {
        !found
      } else {
        found
      }
    }
  }
}

///|
fn reference_closure(
  nfa : ReferenceNfa,
  seeds : Array[Int32],
  position : Int32,
  input_length : Int32,
) -> Array[Int32] {
  let stack : Array[Int32] = []
  for seed in seeds {
    stack.push(seed)
  }
  let seen : Array[Bool] = Array::make(nfa.states.length(), false)
  let result : Array[Int32] = []
  let mut cursor : Int32 = 0
  while cursor < stack.length() {
    let index = stack[cursor]
    cursor = cursor + 1
    if index >= 0 && !seen[index] {
      seen[index] = true
      let state = nfa.states[index]
      match state.kind {
        Epsilon => if state.out1 >= 0 { stack.push(state.out1) }
        Split => {
          if state.out1 >= 0 {
            stack.push(state.out1)
          }
          if state.out2 >= 0 {
            stack.push(state.out2)
          }
        }
        Begin => if position == 0 && state.out1 >= 0 { stack.push(state.out1) }
        End =>
          if position == input_length && state.out1 >= 0 {
            stack.push(state.out1)
          }
        Consume(_) | Accept => result.push(index)
      }
    }
  }
  result
}

///|
fn reference_find(nfa : ReferenceNfa, input : Array[Char]) -> (Int32, Int32)? {
  let mut start : Int32 = 0
  while start <= input.length() {
    let current_start : Array[Int32] = [nfa.start]
    let mut active = reference_closure(
      nfa,
      current_start,
      start,
      input.length(),
    )
    let mut position = start
    let mut last_end : Int32? = None
    while true {
      let mut accepted = false
      for state_index in active {
        if (match nfa.states[state_index].kind {
            Accept => true
            _ => false
          }) {
          accepted = true
        }
      }
      if accepted {
        last_end = Some(position)
      }
      if position >= input.length() || active.is_empty() {
        break
      }
      let next_seeds : Array[Int32] = []
      for state_index in active {
        let state = nfa.states[state_index]
        match state.kind {
          Consume(predicate) =>
            if state.out1 >= 0 && reference_matches(predicate, input[position]) {
              next_seeds.push(state.out1)
            }
          _ => ()
        }
      }
      position = position + 1
      active = reference_closure(nfa, next_seeds, position, input.length())
    }
    match last_end {
      Some(end) => return Some((start, end))
      None => start = start + 1
    }
  }
  None
}
