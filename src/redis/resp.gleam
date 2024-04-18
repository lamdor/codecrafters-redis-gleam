import gleam/bit_array
import gleam/bytes_builder.{type BytesBuilder}
import gleam/int
import gleam/list
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
  use #(resp, _) <- result.map(decode_next_at_position(bits, 0))
  resp
}

fn decode_next_at_position(
  bits: BitArray,
  pos: Int,
) -> Result(#(Resp, Int), Nil) {
  use first_char <- result.try(bit_array.slice(from: bits, at: pos, take: 1))
  case first_char {
    <<"+":utf8>> -> decode_simple_string(bits, pos + 1)
    <<"$":utf8>> -> decode_bulk_string(bits, pos + 1)
    <<":":utf8>> -> decode_integer(bits, pos + 1)
    <<"*":utf8>> -> decode_array(bits, pos + 1)
    _ -> Error(Nil)
  }
}

fn decode_simple_string(bits: BitArray, pos: Int) -> Result(#(Resp, Int), Nil) {
  use #(rest, pos) <- result.try(read_until_terminator(bits, pos))
  use str <- result.map(bit_array.to_string(rest))
  #(SimpleString(str), pos)
}

fn decode_integer(bits: BitArray, pos: Int) -> Result(#(Resp, Int), Nil) {
  use #(rest, pos) <- result.try(read_until_terminator(bits, pos))
  use i <- result.map(result.try(bit_array.to_string(rest), int.parse))
  #(Integer(i), pos)
}

fn decode_bulk_string(bits: BitArray, pos: Int) -> Result(#(Resp, Int), Nil) {
  use #(str_length_as_bits, pos) <- result.try(read_until_terminator(bits, pos))
  use str_length <- result.try(parse_bits_string_to_int(str_length_as_bits))
  case str_length {
    -1 -> Ok(#(Null(Nil), pos))
    _ -> {
      use #(str, pos) <- result.try(read_until_terminator(bits, pos))
      use str <- result.try(bit_array.to_string(str))

      case string.length(str) == str_length {
        True -> Ok(#(BulkString(str), pos))
        False -> Error(Nil)
      }
    }
  }
}

fn parse_bits_string_to_int(bits: BitArray) -> Result(Int, Nil) {
  result.try(bit_array.to_string(bits), int.parse)
}

fn decode_array(bits: BitArray, pos: Int) -> Result(#(Resp, Int), Nil) {
  use #(number_of_elements_str, pos) <- result.try(read_until_terminator(
    bits,
    pos,
  ))
  use number_of_elements <- result.try(parse_bits_string_to_int(
    number_of_elements_str,
  ))
  use #(elems_reversed, pos) <- result.map(
    decode_array_loop(bits, pos, number_of_elements, []),
  )
  #(Array(list.reverse(elems_reversed)), pos)
}

fn decode_array_loop(
  bits: BitArray,
  pos: Int,
  number_of_elements: Int,
  accum: List(Resp),
) -> Result(#(List(Resp), Int), Nil) {
  case number_of_elements > 0 {
    False -> Ok(#(accum, pos))
    _ -> {
      let maybe_next_elem_and_pos = decode_next_at_position(bits, pos)
      case maybe_next_elem_and_pos {
        Ok(#(next_elem, next_pos)) ->
          decode_array_loop(bits, next_pos, number_of_elements - 1, [
            next_elem,
            ..accum
          ])
        Error(_) -> Error(Nil)
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
  read_until_terminator_loop(bits, at, <<>>)
}

fn read_until_terminator_loop(
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
          read_until_terminator_loop(bits, at + 1, bit_array.append(read, next))
      }
  }
}

/// Encode a simple string
/// Simple strings are encoded as a plus (+) character, followed by a string. The string mustn't contain a CR (\r) or LF (\n) character and is terminated by CRLF (i.e., \r\n).
/// 
pub fn simple_string_bytes(str: String) -> BytesBuilder {
  string_builder.from_strings(["+", str, terminator_str])
  |> bytes_builder.from_string_builder
}

/// Encode a string into a bulk string
/// A bulk string represents a single binary string. The string can be of any size, but by default, Redis limits it to 512 MB (see the proto-max-bulk-len configuration directive).
pub fn bulk_string_bytes(str: String) -> BytesBuilder {
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

pub fn null_bytes() -> BytesBuilder {
  bytes_builder.from_string("$-1\r\n")
}

/// Encode a simple error
pub fn simple_error_bytes(str: String) -> BytesBuilder {
  string_builder.from_strings(["-", str, terminator_str])
  |> bytes_builder.from_string_builder
}

/// Encode an integer
pub fn integer_bytes(i: Int) -> BytesBuilder {
  string_builder.from_strings([":", int.to_string(i), terminator_str])
  |> bytes_builder.from_string_builder
}

/// Encode an array
pub fn array_bytes(l: List(BytesBuilder)) -> BytesBuilder {
  let number_of_elements = list.length(l)

  let list_header =
    string_builder.from_strings([
      "*",
      int.to_string(number_of_elements),
      terminator_str,
    ])
    |> bytes_builder.from_string_builder

  [list_header, ..l]
  |> bytes_builder.concat
}

pub fn to_string_list(l: List(Resp)) -> Result(List(String), Nil) {
  result.map(to_string_list_loop(l, []), list.reverse)
}

fn to_string_list_loop(
  l: List(Resp),
  accum: List(String),
) -> Result(List(String), Nil) {
  case l {
    [] -> Ok(accum)
    [BulkString(str), ..l] -> to_string_list_loop(l, [str, ..accum])
    [SimpleString(str), ..l] -> to_string_list_loop(l, [str, ..accum])
    _ -> Error(Nil)
  }
}
