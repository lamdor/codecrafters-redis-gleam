import gleam/bit_array
import gleam/bytes_builder.{type BytesBuilder}
import gleam/int
import gleam/result
import gleam/string
import gleam/string_builder

// const terminator_bits = <<"\r\n":utf8>>

const terminator_str = "\r\n"

pub type Resp {
  SimpleString(string: String)
  SimpleError(error_message: String)
  Integer(i: Int)
  Null(Nil)
  BulkString(string: String)
  Array(elements: List(Resp))
}

/// Decode bits to Resp
pub fn decode(bits: BitArray) -> Result(Resp, Nil) {
  use first_char <- result.try(bit_array.slice(from: bits, at: 0, take: 1))
  case first_char {
    <<"+":utf8>> -> decode_simple_string(bits)
    <<"$":utf8>> -> decode_bulk_string(bits)
    <<":":utf8>> -> decode_integer(bits)
    _ -> Error(Nil)
  }
}

fn decode_simple_string(bits: BitArray) -> Result(Resp, Nil) {
  use #(rest, _) <- result.try(read_until_terminator(bits, 1))
  use str <- result.map(bit_array.to_string(rest))
  SimpleString(str)
}

fn decode_integer(bits: BitArray) -> Result(Resp, Nil) {
  use #(rest, _) <- result.try(read_until_terminator(bits, 1))
  use i <- result.map(result.try(bit_array.to_string(rest), int.parse))
  Integer(i)
}

fn decode_bulk_string(bits: BitArray) -> Result(Resp, Nil) {
  use #(str_length_as_bits, pos) <- result.try(read_until_terminator(bits, 1))
  use str_length <- result.try(result.try(
    bit_array.to_string(str_length_as_bits),
    int.parse,
  ))
  case str_length {
    -1 -> Ok(Null(Nil))
    _ -> {
      use #(str, _) <- result.try(read_until_terminator(bits, pos))
      use str <- result.try(bit_array.to_string(str))

      case string.length(str) == str_length {
        True -> Ok(BulkString(str))
        False -> Error(Nil)
      }
    }
  }
}

/// reads the bits start at "at" until it gets to the terminator
/// returns those bits and the new position after the terminator
fn read_until_terminator(
  from bits: BitArray,
  at at: Int,
) -> Result(#(BitArray, Int), Nil) {
  read_loop_until_terminator(bits, at, <<>>)
}

fn read_loop_until_terminator(
  bits: BitArray,
  at: Int,
  read: BitArray,
) -> Result(#(BitArray, Int), Nil) {
  // do not use `use` syntax as then it's not tail recursive
  let maybe_next = bit_array.slice(from: bits, at: at, take: 1)
  let maybe_nexttwo = bit_array.slice(from: bits, at: at, take: 2)
  case maybe_nexttwo {
    Ok(<<"\r\n":utf8>>) -> Ok(#(read, at + 2))
    Error(_) -> Error(Nil)
    _ ->
      case maybe_next {
        Error(_) -> Error(Nil)
        Ok(next) ->
          read_loop_until_terminator(bits, at + 1, bit_array.append(read, next))
      }
  }
}

/// Encode a simple string
/// Simple strings are encoded as a plus (+) character, followed by a string. The string mustn't contain a CR (\r) or LF (\n) character and is terminated by CRLF (i.e., \r\n).
/// 
pub fn simple_string(str: String) -> BytesBuilder {
  string_builder.from_strings(["+", str, terminator_str])
  |> bytes_builder.from_string_builder
}

/// Encode a string into a bulk string
/// A bulk string represents a single binary string. The string can be of any size, but by default, Redis limits it to 512 MB (see the proto-max-bulk-len configuration directive).
pub fn bulk_string(str: String) -> BytesBuilder {
  string_builder.from_strings([
    "$",
    string.length(str)
      |> int.to_string,
    terminator_str,
    str,
    terminator_str,
  ])
  |> bytes_builder.from_string_builder
}

pub fn null() -> BytesBuilder {
  bytes_builder.from_string("$-1\r\n")
}

/// Encode a simple error
pub fn simple_error(str: String) -> BytesBuilder {
  string_builder.from_strings(["-", str, terminator_str])
  |> bytes_builder.from_string_builder
}

/// Encode an integer
pub fn integer(i: Int) -> BytesBuilder {
  string_builder.from_strings([":", int.to_string(i), terminator_str])
  |> bytes_builder.from_string_builder
}
