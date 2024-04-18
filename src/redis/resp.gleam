import gleam/bit_array
import gleam/bytes_builder.{type BytesBuilder}
import gleam/string_builder
import gleam/result

const terminator = "\r\n"

pub type Resp {
  SimpleString(string: String)
  SimpleError(error_message: String)
  Integer(i: Int)
  Null
  BulkString(string: String)
  Array(elements: List(Resp))
}

/// Decode bits to Resp
pub fn decode(bits: BitArray) -> Result(Resp, Nil) {
  use first_char <- result.try(bit_array.slice(from: bits, at: 0, take: 1))
  case first_char {
    <<"+":utf8>> -> decode_simple_string(bits)
    _ -> Error(Nil)
  }
}

fn decode_simple_string(bits: BitArray) -> Result(Resp, Nil) {
  let length = bit_array.byte_size(bits)
  use rest_wo_terminator <- result.try(bit_array.slice(
    from: bits,
    at: 1,
    take: length - 3,
  ))
  use string <- result.map(bit_array.to_string(rest_wo_terminator))
  SimpleString(string)
}

/// Encode a simple string
/// Simple strings are encoded as a plus (+) character, followed by a string. The string mustn't contain a CR (\r) or LF (\n) character and is terminated by CRLF (i.e., \r\n).
/// 
pub fn simple_string(str: String) -> BytesBuilder {
  string_builder.from_strings(["+", str, terminator])
  |> bytes_builder.from_string_builder
}
