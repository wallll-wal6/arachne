///|
/// Adapt the Perl frontend of `walkzzz/re-mbt` for ASCII-only contracts.
///
/// re-mbt exposes byte-oriented APIs. This adapter intentionally accepts only
/// ASCII patterns and inputs, where byte offsets equal MoonBit StringView code
/// unit offsets. It reports non-ASCII values as adapter-domain errors rather
/// than guessing at an encoding conversion.
pub fn rembt_ascii_perl_adapter() -> EngineAdapter {
  EngineAdapter::new(id="walkzzz/re-mbt/Perl (ASCII)", compile=pattern => {
    if !is_ascii(pattern) {
      return Err(
        "adapter-domain: re-mbt Perl adapter currently accepts ASCII patterns only",
      )
    }
    let compiled = Ok(@rembt.Perl::compile_pat(@rembt.sb(pattern))) catch {
      _ => Err("re-mbt Perl frontend rejected the pattern")
    }
    match compiled {
      Err(message) => Err(message)
      Ok(regex) =>
        Ok(
          CompiledMatcher::new(observe=input => {
            if !is_ascii(input) {
              return Err(
                "adapter-domain: re-mbt Perl adapter currently accepts ASCII inputs only",
              )
            }
            let groups_result = Ok(@rembt.exec_opt(regex, @rembt.sb(input))) catch {
              _ => Err("re-mbt Perl matcher raised an error")
            }
            match groups_result {
              Err(message) => Err(message)
              Ok(None) => Ok(None)
              Ok(Some(groups)) => {
                let text = match @rembt.GroupT::get_opt(groups, 0) {
                  Some(bytes) => @rembt.bs(bytes)
                  None => ""
                }
                let (start, end) = match @rembt.GroupT::offset_opt(groups, 0) {
                  Some(offsets) => offsets
                  None =>
                    return Err(
                      "re-mbt returned a match without group-zero offsets",
                    )
                }
                let captures : Array[String?] = []
                for index = 1
                    index < @rembt.GroupT::nb_groups(groups)
                    index = index + 1 {
                  captures.push(
                    @rembt.GroupT::get_opt(groups, index).map(bytes => {
                      @rembt.bs(bytes)
                    }),
                  )
                }
                Ok(Some({ text, start, end, captures, }))
              }
            }
          }),
        )
    }
  })
}

///|
fn is_ascii(value : String) -> Bool {
  for char in value {
    if char.to_int() > 127 {
      return false
    }
  }
  true
}
