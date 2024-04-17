import gleam/bytes_builder.{type BytesBuilder}
import gleam/string_builder

const terminator = "\r\n"

/// Encode a simple string
/// Simple strings are encoded as a plus (+) character, followed by a string. The string mustn't contain a CR (\r) or LF (\n) character and is terminated by CRLF (i.e., \r\n).
/// 
pub fn simple_string(str: String) -> BytesBuilder {
  string_builder.from_strings(["+", str, terminator])
  |> bytes_builder.from_string_builder
}
