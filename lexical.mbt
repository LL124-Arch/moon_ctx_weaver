///|
fn flush_lexical_token(
  token : StringBuilder,
  terms : Map[String, Bool],
) -> Unit {
  if !token.is_empty() {
    terms[token.to_string()] = true
    token.reset()
  }
}

///|
fn lexical_terms(source : String) -> Map[String, Bool] {
  let terms : Map[String, Bool] = Map([])
  let token = StringBuilder()
  for character in source {
    if character.is_ascii_alphabetic() || character.is_ascii_digit() {
      token.write_char(character.to_ascii_lowercase())
    } else {
      flush_lexical_token(token, terms)
      if !character.is_ascii() &&
        character.is_printable() &&
        !character.is_whitespace() {
        terms[character.to_string()] = true
      }
    }
  }
  flush_lexical_token(token, terms)
  terms
}

///|
/// Score lexical relevance from 0 to 100 without allocating model calls.
///
/// Unique query-term coverage contributes 80 percent of the score and text
/// precision contributes 20 percent. ASCII words are case-insensitive; each
/// printable non-ASCII character is matched as a term.
pub fn lexical_score(query : String, text : String) -> Int {
  let query_terms = lexical_terms(query)
  let text_terms = lexical_terms(text)
  if query_terms.is_empty() || text_terms.is_empty() {
    return 0
  }
  let mut matches = 0
  for term, _ in query_terms {
    if text_terms.contains(term) {
      matches += 1
    }
  }
  let coverage = matches * 100 / query_terms.length()
  let precision = matches * 100 / text_terms.length()
  (coverage * 4 + precision) / 5
}
